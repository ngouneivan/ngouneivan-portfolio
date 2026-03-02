# Importer le fichier CSV
$VMs = Import-Csv -Path "C:\configs\vms.csv"

foreach ($VM in $Vms) {

    # Créer le disque de différenciation
    New-VHD -ParentPath "C:\DISK\$($vm.NameParent).vhdx" -Path "C:\v-host\$($vm.Name).vhdx" -Differencing

    # Créer la VM
    New-VM -Name $vm.Name -MemoryStartupBytes $([int64]$vm.ram*1MB) -Generation 2 -VHDPath "C:\v-host\$($vm.Name).vhdx"

    # Supprimer la carte réseau par défaut
    Get-VMNetworkAdapter -VMName $vm.Name | Remove-VMNetworkAdapter

    # Ajouter la carte réseau "AIX"
    Add-VMNetworkAdapter -VMName $vm.Name -SwitchName $vm.switch

   # Monter le VHDX
    Mount-VHD -Path "C:\v-host\$($vm.Name).vhdx"

 # Copier le fichier unattend.xml dans le VHDX
    Copy-Item "C:\DISK\Unattend\$($vm.type)\unattend.xml" -Destination D:\
 
    # Ejection du VHD de la VM
    Dismount-DiskImage -ImagePath "C:\v-host\$($VM.Name).vhdx"

}

# Démarrer SRV-02 et SRV-01
Start-VM SRV-02
Start-VM SRV-01

Start-Sleep 60

$User = "SRV-02\Administrateur"
$PWord = ConvertTo-SecureString -String "Azerty1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$User1 = "SRV-01\Administrateur"
$PWord1 = ConvertTo-SecureString -String "Azerty1" -AsPlainText -Force
$Credential1 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User1, $PWord1

# Ajout de la configuration IP pour SRV-02
Invoke-Command -VMName SRV-02 -Credential $Credential -ScriptBlock {
    New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.1.2" -PrefixLength 24 -DefaultGateway "192.168.1.1"
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.1.2"
}

# Ajout de la configuration IP pour SRV-01
Invoke-Command -VMName SRV-01 -Credential $Credential1 -ScriptBlock {
    New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.1.5" -PrefixLength 24 -DefaultGateway "192.168.1.1"
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.1.2"
}


Invoke-Command -VMName SRV-01 -Credential $Credential1 -ScriptBlock {
    # Autoriser le ping entrant
    New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Direction Inbound -Action Allow
    # Autoriser le ping sortant
    New-NetFirewallRule -DisplayName "Allow ICMPv4-Out" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Direction Outbound -Action Allow

    # Afficher un message en vert
    Write-Host "Configuration du pare-feu réussie !" -ForegroundColor Green
}





$DomainName = "aix.lan"
$DomainNetbiosName = "AIX"
$ClearAdministratorPassword = "Azerty1"
$SafeModeAdministratorPassword = $ClearAdministratorPassword | ConvertTo-SecureString -AsPlainText -Force

Invoke-Command -VMName SRV-02 -Credential $Credential -ScriptBlock {Install-WindowsFeature -Name AD-Domain-Services,DNS -IncludeManagementTools}


Invoke-Command -VMName SRV-02 -Credential $Credential -ScriptBlock {

$DomainName = "aix.lan"
$DomainNetbiosName = "AIX"
$ClearAdministratorPassword = "Azerty1"
$SafeModeAdministratorPassword = $ClearAdministratorPassword | ConvertTo-SecureString -AsPlainText -Force

 
        Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "$DomainName" `
-DomainNetbiosName "$DomainNetbiosName" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true `
-SafeModeAdministratorPassword $SafeModeAdministratorPassword

}


# Pause de 5 minutes pour permettre au serveur de redémarrer
Start-Sleep -Seconds 300



$User = "AIX\Administrateur"
$PWord = ConvertTo-SecureString -String "Azerty1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord


# Autoriser le ping entrant
try {
    netsh advfirewall firewall add rule name="Autoriser ICMPv4 entrant" protocol=icmpv4:8,any dir=in action=allow
    netsh advfirewall firewall add rule name="Autoriser ICMPv6 entrant" protocol=icmpv6:8,any dir=in action=allow
    Write-Host "Ping entrant autorisé avec succès." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'autorisation du ping entrant." -ForegroundColor Red
}

# Autoriser le ping sortant
try {
    netsh advfirewall firewall add rule name="Autoriser ICMPv4 sortant" protocol=icmpv4:8,any dir=out action=allow
    netsh advfirewall firewall add rule name="Autoriser ICMPv6 sortant" protocol=icmpv6:8,any dir=out action=allow
    Write-Host "Ping sortant autorisé avec succès." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'autorisation du ping sortant." -ForegroundColor Red
}



Invoke-Command -VMName SRV-02 -Credential $Credential -ScriptBlock {
    # Crée la zone inverse s'il n'existe pas
    $zone = Get-DnsServerZone -Name "1.168.192.in-addr.arpa" -ErrorAction SilentlyContinue
    if ($null -eq $zone) {
        Add-DnsServerPrimaryZone -NetworkId "192.168.1.0/24" -ReplicationScope "Forest" -PassThru
        Write-Host "La zone inverse 1.168.192.in-addr.arpa a été créée."
    } else {
        Write-Host "La zone inverse 1.168.192.in-addr.arpa existe déjà."
    }

    # Ajoute l'enregistrement A pour SRV-01 s'il n'existe pas
    $recordASRV01 = Get-DnsServerResourceRecord -ZoneName "aix.lan" -RRType "A" -Name "SRV-01" -ErrorAction SilentlyContinue
    if ($null -eq $recordASRV01) {
        Add-DnsServerResourceRecordA -Name "SRV-01" -IPv4Address "192.168.1.5" -ZoneName "aix.lan"
        if ($?) {
            Write-Host "L'enregistrement A pour SRV-01 a été ajouté avec succès dans la zone directe."
        } else {
            Write-Host "Erreur lors de l'ajout de l'enregistrement A pour SRV-01 dans la zone directe."
        }
    }

    # Ajoute l'enregistrement A pour CLIENT s'il n'existe pas
    $recordACLIENT = Get-DnsServerResourceRecord -ZoneName "aix.lan" -RRType "A" -Name "CLIENT" -ErrorAction SilentlyContinue
    if ($null -eq $recordACLIENT) {
        Add-DnsServerResourceRecordA -Name "CLIENT" -IPv4Address "192.168.1.10" -ZoneName "aix.lan"
        if ($?) {
            Write-Host "L'enregistrement A pour CLIENT a été ajouté avec succès dans la zone directe."
        } else {
            Write-Host "Erreur lors de l'ajout de l'enregistrement A pour CLIENT dans la zone directe."
        }
    }

    # Vérifie si l'enregistrement PTR pour SRV-02 existe
    $recordPTRSRV02 = Get-DnsServerResourceRecord -ZoneName "1.168.192.in-addr.arpa" -RRType "PTR" -Name "2" -ErrorAction SilentlyContinue
    if ($null -eq $recordPTRSRV02) {
        # Ajoute l'enregistrement PTR pour SRV-02 s'il n'existe pas
        Add-DnsServerResourceRecordPtr -Name "2" -PtrDomainName "SRV-02.aix.lan" -ZoneName "1.168.192.in-addr.arpa"
        if ($?) {
            Write-Host "L'enregistrement PTR pour SRV-02 a été ajouté avec succès dans la zone inverse."
        } else {
            Write-Host "Erreur lors de l'ajout de l'enregistrement PTR pour SRV-02 dans la zone inverse."
        }
    }

    # Vérifie si l'enregistrement PTR pour SRV-01 existe
    $recordPTRSRV01 = Get-DnsServerResourceRecord -ZoneName "1.168.192.in-addr.arpa" -RRType "PTR" -Name "5" -ErrorAction SilentlyContinue
    if ($null -eq $recordPTRSRV01) {
        # Ajoute l'enregistrement PTR pour SRV-01 s'il n'existe pas
        Add-DnsServerResourceRecordPtr -Name "5" -PtrDomainName "SRV-01.aix.lan" -ZoneName "1.168.192.in-addr.arpa"
        if ($?) {
            Write-Host "L'enregistrement PTR pour SRV-01 a été ajouté avec succès dans la zone inverse."
        } else {
            Write-Host "Erreur lors de l'ajout de l'enregistrement PTR pour SRV-01 dans la zone inverse."
        }
    } else {
        # Vérifie si l'enregistrement PTR pour SRV-01 pointe vers la mauvaise adresse IP
        if ($recordPTRSRV01.RecordData.PtrDomainName -ne "192.168.1.5") {
            # Supprime l'enregistrement PTR incorrect pour SRV-01
            Remove-DnsServerResourceRecord -ZoneName "1.168.192.in-addr.arpa" -RRType "PTR" -Name "5" -RecordData "SRV-01.aix.lan"
            # Ajoute l'enregistrement PTR correct pour SRV-01
            Add-DnsServerResourceRecordPtr -Name "5" -PtrDomainName "SRV-01.aix.lan" -ZoneName "1.168.192.in-addr.arpa"
            if ($?) {
                Write-Host "L'enregistrement PTR pour SRV-01 a été mis à jour avec succès dans la zone inverse."
            } else {
                Write-Host "Erreur lors de la mise à jour de l'enregistrement PTR pour SRV-01 dans la zone inverse."
            }
        }
    }

    # Vérifie si l'enregistrement PTR pour CLIENT existe
    $recordPTRCLIENT = Get-DnsServerResourceRecord -ZoneName "1.168.192.in-addr.arpa" -RRType "PTR" -Name "10" -ErrorAction SilentlyContinue
    if ($null -eq $recordPTRCLIENT) {
        # Ajoute l'enregistrement PTR pour CLIENT s'il n'existe pas
        Add-DnsServerResourceRecordPtr -Name "10" -PtrDomainName "CLIENT.aix.lan" -ZoneName "1.168.192.in-addr.arpa"
        if ($?) {
            Write-Host "L'enregistrement PTR pour CLIENT a été ajouté avec succès dans la zone inverse."
        } else {
            Write-Host "Erreur lors de l'ajout de l'enregistrement PTR pour CLIENT dans la zone inverse."
        }
    }
}



# Pause d'1 minute pour permettre au serveur de redémarrer
Start-Sleep -Seconds 60

# Ajout du serveur SRV-01 au domaine
Invoke-Command -VMName SRV-01 -Credential $Credential1 -ScriptBlock {
    $domain = "aix.lan"
    $password = ConvertTo-SecureString -String "Azerty1" -AsPlainText -Force
    $username = "$domain\Administrateur"
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)

    try {
        Add-Computer -DomainName $domain -Credential $credential -Restart -Force
        Write-Host "Le serveur SRV-01 a été ajouté avec succès au domaine $domain et va redémarrer." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de l'ajout du serveur SRV-01 au domaine $domain." -ForegroundColor Red
    }
}





# Pause d'1 minute pour permettre au serveur de redémarrer
Start-Sleep -Seconds 60


# Création de l'utilisateur user1 dans le groupe TEST-USERS sur le serveur SRV-02
Invoke-Command -VMName SRV-02 -Credential $Credential -ScriptBlock {
    Import-Module ActiveDirectory
    $groupName = "TEST-USERS"
    $userName = "user1"
    $password = ConvertTo-SecureString -String "Azerty1" -AsPlainText -Force
    $userCredential = New-Object System.Management.Automation.PSCredential($userName, $password)

    # Vérifie si le groupe TEST-USERS existe
    if (!(Get-ADGroup -Filter { Name -eq $groupName })) {
        # Crée le groupe TEST-USERS s'il n'existe pas
        New-ADGroup -Name $groupName -GroupScope Global -PassThru
    }

    # Crée l'utilisateur user1 et l'ajoute au groupe TEST-USERS
    try {
        $newUser = New-ADUser -SamAccountName $userName -UserPrincipalName "$userName@$domain" -Name $userName -GivenName $userName -Surname $userName -Enabled $true -DisplayName "$userName $userName" -Description "Test User" -AccountPassword $password -PassThru
        if ($newUser) {
            Add-ADGroupMember -Identity $groupName -Members $newUser.SamAccountName
            Write-Host "L'utilisateur $userName a été créé avec succès et ajouté au groupe $groupName." -ForegroundColor Green
        } else {
            Write-Host "Erreur lors de la création de l'utilisateur $userName." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'ajout de l'utilisateur $userName au groupe $groupName." -ForegroundColor Red
    }
}


# Installer le rôle DHCP
Invoke-Command -VMName SRV-01 -Credential $Credential1 -ScriptBlock {
    if ((Get-WindowsFeature -Name DHCP).InstallState -eq 'Installed') {
        Write-Host "Le rôle DHCP est déjà installé sur le serveur SRV-01." -ForegroundColor Yellow
    } else {
        try {
            Install-WindowsFeature -Name DHCP -IncludeManagementTools
            Write-Host "Le rôle DHCP a été installé avec succès sur le serveur SRV-01." -ForegroundColor Green
            # Supprimer le drapeau d'installation
            Clear-WindowsFeatureInstallationFlag
        } catch {
            Write-Host "Erreur lors de l'installation du rôle DHCP sur le serveur SRV-01." -ForegroundColor Red
        }
    }
}

# Configurer la plage DHCP
Invoke-Command -VMName SRV-01 -Credential $Credential1 -ScriptBlock {
    if ((Get-DhcpServerv4Scope -ScopeId "192.168.1.0") -ne $null) {
        Write-Host "La plage DHCP est déjà configurée sur le serveur SRV-01." -ForegroundColor Yellow
    } else {
        try {
            $dhcpScopeParams = @{
                Name               = "aix.lan"
                StartRange         = "192.168.1.10"
                EndRange           = "192.168.1.50"
                SubnetMask         = "255.255.255.0"
                LeaseDuration      = (New-TimeSpan -Hours 8)
                State              = "Active"
                PassThru           = $true
            }
            Add-DhcpServerv4Scope @dhcpScopeParams

            # Configurer les options du scope
            Set-DhcpServerv4OptionValue -ScopeId "192.168.1.0" -DnsServer "192.168.1.2" -Router "192.168.1.1"
            
            # Exclure les adresses spécifiques
            Add-DhcpServerv4ExclusionRange -ScopeId "192.168.1.0" -StartRange "192.168.1.2" -EndRange "192.168.1.2"
            Add-DhcpServerv4ExclusionRange -ScopeId "192.168.1.0" -StartRange "192.168.1.5" -EndRange "192.168.1.5"

            # Activer le DHCP
            Set-DhcpServerv4Scope -ScopeId "192.168.1.0" -State Active

            Write-Host "La plage DHCP a été configurée avec succès sur le serveur SRV-01." -ForegroundColor Green
        } catch {
            Write-Host "Erreur lors de la configuration de la plage DHCP sur le serveur SRV-01." -ForegroundColor Red
        }
    }
}


# Vérifier si le service DHCP est démarré
Invoke-Command -VMName SRV-01 -Credential $Credential1 -ScriptBlock {
    if ((Get-Service -Name 'DHCPServer').Status -eq 'Running') {
        Write-Host "Le service DHCP est en cours d'exécution sur le serveur SRV-01." -ForegroundColor Green
    } else {
        Write-Host "Le service DHCP n'est pas en cours d'exécution sur le serveur SRV-01." -ForegroundColor Red
    }
}




# Pause d'1 minute pour permettre au serveur de redémarrer
Start-Sleep -Seconds 60

$User = "AIX\Administrateur"
$PWord = ConvertTo-SecureString -String "Azerty1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

Invoke-Command -VMName SRV-02 -Credential $Credential -ScriptBlock {
    # Importer le module Active Directory
    Import-Module ActiveDirectory

    # Vérifier si le module DHCP Server est installé
    if (!(Get-WindowsFeature -Name 'DHCP' | Where-Object {$_.InstallState -eq 'Installed'})) {
        Write-Host "Le module DHCP Server n'est pas installé. L'installation commence..."
        Install-WindowsFeature DHCP -IncludeManagementTools
        Write-Host "Le module DHCP Server a été installé avec succès." -ForegroundColor Green
    } else {
        Write-Host "Le module DHCP Server est déjà installé." -ForegroundColor Yellow
    }

    # Importer le module DHCP Server
    Import-Module DhcpServer

    # Vérifier si la commande Add-DhcpServerInDC est disponible
    if (!(Get-Command Add-DhcpServerInDC -ErrorAction SilentlyContinue)) {
        Write-Host "La commande Add-DhcpServerInDC n'est pas disponible. Vérifiez votre installation et vos privilèges."
        return
    }

    # Autoriser le serveur DHCP (SRV-01) dans le contrôleur de domaine
    try {
        Add-DhcpServerInDC -DnsName "SRV-01.aix.lan" -IPAddress "192.168.1.5"
        Write-Host "Le serveur DHCP a été autorisé avec succès dans le domaine." -ForegroundColor Green
    } catch {
        Write-Host "Le serveur DHCP est déjà autorisé dans le domaine." -ForegroundColor Yellow
    }
}




# Démarrer CLIENT
Start-VM CLIENT

# Pause d'1 minute pour permettre au serveur de redémarrer
Start-Sleep -Seconds 300

$User2 = "CLIENT\USER"
$PWord2 = ConvertTo-SecureString -String "lACASTA1," -AsPlainText -Force
$Credential2 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User2, $PWord2


Invoke-Command -VMName CLIENT -Credential $Credential2 -ScriptBlock {
    # Autoriser le ping entrant
    New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Direction Inbound -Action Allow
    # Autoriser le ping sortant
    New-NetFirewallRule -DisplayName "Allow ICMPv4-Out" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Direction Outbound -Action Allow

    # Afficher un message en vert
    Write-Host "Configuration du pare-feu réussie !" -ForegroundColor Green
}




# Ajout du CLIENT au domaine
Invoke-Command -VMName CLIENT -Credential $Credential2 -ScriptBlock {
    $domain = "aix.lan"
    $password = ConvertTo-SecureString -String "lACASTA1," -AsPlainText -Force
    $username = "$domain\Administrateur"
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)

    try {
        Add-Computer -DomainName $domain -Credential $credential2 -Restart -Force
        Write-Host "Le CLIENT a été ajouté avec succès au domaine $domain et va redémarrer." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de l'ajout du CLIENT au domaine $domain." -ForegroundColor Red
    }
}

Start-Sleep -Seconds 10

function Votre-Script {
    # Votre code ici
    Start-Sleep -s 2  # Remplacez ceci par votre code
}

function Main {
    Votre-Script
    Write-Host "Nous arrivons à la fin de l'exécution de votre script." -ForegroundColor Yellow
    Write-Host "Merci pour vos compétences et votre détermination! À bientôt 😊" -ForegroundColor Yellow
}

Main
