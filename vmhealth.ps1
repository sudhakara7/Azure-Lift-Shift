
#vmhealth.ps1
#Usage:
#.\vmhealth.ps1 start
#.\vmhealth.ps1 stop
#.\vmhealth.ps1 status

##=================================================##
##====To check the vm status , stop ,  start ======##
##=================================================##
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start","stop","status")]
    [string]$Action
)

# ===============================
# Azure Login Check
# ===============================

$context = Get-AzContext

if ($null -eq $context) {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}


# ===============================
# Input
# ===============================

$RG = Read-Host "Enter Resource Group Name"

$VMFile = Read-Host "Enter VM List File Path"

if (!(Test-Path $VMFile)) {

    Write-Host "VM list file not found: $VMFile" -ForegroundColor Red
    exit
}


$VMs = Get-Content $VMFile | Where-Object {
    $_.Trim() -ne ""
}


if ($VMs.Count -eq 0) {

    Write-Host "No VM names found in file" -ForegroundColor Red
    exit
}



# ===============================
# Get VM Status Function
# ===============================

function Get-VMStatus {

    param(
        [string]$RGName,
        [string]$VMName
    )


    try {

        $status = Get-AzVM `
            -ResourceGroupName $RGName `
            -Name $VMName `
            -Status


        $power = $status.Statuses |
            Where-Object {
                $_.Code -like "PowerState/*"
            }


        return $power.DisplayStatus

    }
    catch {

        return "NOT FOUND"
    }

}



# ===============================
# Status Display
# ===============================

function Show-Status {


    Clear-Host

    Write-Host ""
    Write-Host "Azure VM Health Status" -ForegroundColor Cyan
    Write-Host "========================================"


    foreach($VM in $VMs) {


        $state = Get-VMStatus $RG $VM


        switch($state) {


            "VM running" {

                Write-Host `
                ("{0,-35} {1}" -f $VM,$state) `
                -ForegroundColor Green

            }


            "VM deallocated" {


                Write-Host `
                ("{0,-35} {1}" -f $VM,$state) `
                -ForegroundColor Yellow

            }


            default {


                Write-Host `
                ("{0,-35} {1}" -f $VM,$state) `
                -ForegroundColor Red

            }

        }

    }


    Write-Host "========================================"

}



# ===============================
# START VM
# ===============================

if ($Action -eq "start") {


    Write-Host ""
    Write-Host "Submitting START requests..." `
        -ForegroundColor Yellow


    foreach($VM in $VMs) {


        Write-Host "Starting $VM"


        Start-AzVM `
            -ResourceGroupName $RG `
            -Name $VM `
            -NoWait


    }


    Write-Host ""
    Write-Host "All start requests submitted" `
        -ForegroundColor Green



    do {


        Clear-Host

        Write-Host "START Progress"
        Write-Host "================================"


        $pending=$false


        foreach($VM in $VMs) {


            $state = Get-VMStatus $RG $VM


            Write-Host `
            ("{0,-35} {1}" -f $VM,$state)


            if($state -ne "VM running") {

                $pending=$true

            }


        }


        if($pending){

            Start-Sleep 15

        }


    }
    while($pending)


    Write-Host ""
    Write-Host "All VMs Started" `
        -ForegroundColor Green

}



# ===============================
# STOP VM
# ===============================


if ($Action -eq "stop") {



    Write-Host ""
    Write-Host "Submitting STOP requests..." `
        -ForegroundColor Yellow



    foreach($VM in $VMs) {



        Write-Host "Stopping $VM"


        Stop-AzVM `
            -ResourceGroupName $RG `
            -Name $VM `
            -Force `
            -NoWait


    }



    Write-Host ""
    Write-Host "All stop requests submitted" `
        -ForegroundColor Green



    do {


        Clear-Host


        Write-Host "STOP Progress"
        Write-Host "================================"


        $pending=$false



        foreach($VM in $VMs) {


            $state = Get-VMStatus $RG $VM



            Write-Host `
            ("{0,-35} {1}" -f $VM,$state)



            if($state -ne "VM deallocated") {

                $pending=$true

            }


        }



        if($pending){

            Start-Sleep 15

        }



    }
    while($pending)



    Write-Host ""
    Write-Host "All VMs Stopped" `
        -ForegroundColor Green

}



# ===============================
# STATUS ONLY
# ===============================

if ($Action -eq "status") {

    Show-Status

}
