while($true) {
    $cpu = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select-Object -ExpandProperty Average
    Write-Host "Charge CPU actuelle : $cpu %"
    
    if ($cpu -gt 80) {
        Write-Host "ALERTE : Surcharge detectee ! Envoi du signal d'auto-scaling..." -ForegroundColor Red
        # Ici, on simule l'appel à Ansible pour déployer la configuration de secours
        break
    }
    Start-Sleep -Seconds 5
}