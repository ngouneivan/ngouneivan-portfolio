Import-Module ActiveDirectory

# ==============================================================================
# CONFIGURATION DYNAMIQUE
# ==============================================================================
$DomainDN       = (Get-ADDomain).DistinguishedName
$ServersRootOU  = "OU=Serveurs,$DomainDN"
$GroupsRootOU   = "OU=GROUPES,$DomainDN"
$StagingOU      = "OU=Serveurs-A-Traiter,$ServersRootOU"
$LogFile        = "C:\Logs\AD_Automation_Master.log"
$GroupSuffixes  = @("Admins", "RDP", "RemoteMgmt", "PerfMonitor", "EventLog")

# Intervalle de repos (300 secondes = 5 minutes)
$SleepInterval  = 300 

# ==============================================================================
# FONCTIONS D'INTELLIGENCE
# ==============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if (-not (Test-Path "C:\Logs")) { New-Item -Path "C:\Logs" -ItemType Directory -Force }
    "[$Stamp] [$Level] $Message" | Out-File -Append $LogFile -Encoding UTF8
    $Color = switch($Level) { "ERROR" {"Red"}; "WARN" {"Yellow"}; "SUCCESS" {"Green"}; Default {"White"} }
    Write-Host "[$Level] $Message" -ForegroundColor $Color
}

function Ensure-OU {
    param([string]$Name, [string]$ParentDN)
    $TargetDN = "OU=$Name,$ParentDN"
    $OU = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$TargetDN'" -ErrorAction SilentlyContinue
    if (-not $OU) {
        try {
            New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ErrorAction Stop
            Write-Log "CRÉATION UO : $Name" "SUCCESS"
        } catch {
            Write-Log "ÉCHEC UO $Name : $($_.Exception.Message)" "ERROR"
            return $null
        }
    }
    return $TargetDN
}

# ==============================================================================
# BOUCLE INFINIE AVEC VÉRIFICATION DU RÔLE PDC
# ==============================================================================

Write-Host "--- MOTEUR D'AUTOMATISATION AD LANCÉ (CTRL+C POUR ARRÊTER) ---" -ForegroundColor Cyan

while ($true) {
    # --- VÉRIFICATION DU RÔLE DE MAÎTRE ---
    $PDCElement = (Get-ADDomain).PDCEmulator
    $CurrentMachine = $env:COMPUTERNAME + "." + $env:USERDNSDOMAIN

    if ($PDCElement -ne $CurrentMachine) {
        # Si ce n'est pas le PDC, on attend sans rien faire
        Write-Host "[WAIT] Ce serveur n'est pas le PDC Emulator ($PDCElement). En attente..." -ForegroundColor Gray
    } else {
        Write-Log "--- DÉMARRAGE DU CYCLE (SERVEUR MAÎTRE : $env:COMPUTERNAME) ---"

        try {
            # 1. SCAN RÉCURSIF (Inclut l'UO de transit)
            $Servers = Get-ADComputer -SearchBase $ServersRootOU -Filter 'OperatingSystem -like "*Server*"' -SearchScope Subtree -Properties DistinguishedName, Name
            Write-Log "Analyse de $($Servers.Count) objets serveurs..."

            foreach ($Srv in $Servers) {
                $SrvName = $Srv.Name
                
                # --- GESTION DU TRANSIT (Ex: SRV-WSUS) ---
                if ($Srv.DistinguishedName -like "*$StagingOU*") {
                    Write-Log "Détection de $SrvName dans l'UO de transit." "WARN"
                    $FinalSrvPath = Ensure-OU -Name $SrvName -ParentDN $ServersRootOU
                    if ($FinalSrvPath) {
                        Move-ADObject -Identity $Srv.DistinguishedName -TargetPath $FinalSrvPath -ErrorAction Stop
                        Write-Log "DÉPLACEMENT : $SrvName déplacé vers $FinalSrvPath" "SUCCESS"
                    }
                }

                # --- GESTION DES GROUPES (Miroir dans GROUPES) ---
                $TargetGroupOU = Ensure-OU -Name $SrvName -ParentDN $GroupsRootOU
                if ($TargetGroupOU) {
                    foreach ($Suffix in $GroupSuffixes) {
                        $GroupName = "G_${SrvName}_$Suffix"
                        if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
                            try {
                                New-ADGroup -Name $GroupName -GroupScope Global -GroupCategory Security -Path $TargetGroupOU -Description "Gestion automatique : $Suffix pour $SrvName" -ErrorAction Stop
                                Write-Log "GROUPE CRÉÉ : $GroupName" "SUCCESS"
                            } catch {
                                Write-Log "ERREUR GROUPE $GroupName : $($_.Exception.Message)" "ERROR"
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Log "ERREUR CRITIQUE : $($_.Exception.Message)" "ERROR"
        }
        Write-Log "--- FIN DU CYCLE. Système Nominal. ---"
    }

    Start-Sleep -Seconds $SleepInterval
}