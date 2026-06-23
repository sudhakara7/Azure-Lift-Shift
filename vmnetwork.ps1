
#./vmnetwork.ps1 status
#./vmnetwork.ps1 enable

#=========================check the network accelerator status either disabled or enabled======#########

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("status","enable")]
    [string]$Action
)


# ===============================
# Azure Login
# ===============================

if ($null -eq (Get-AzContext)) {

    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount

}



# ===============================
# Input
# ===============================


$RG = Read-Host "Enter Resource Group Name"

$VMFile = Read-Host "Enter VM List File Path"


if (!(Test-Path $VMFile)) {

    Write-Host "VM list file not found" -ForegroundColor Red
    exit

}



$VMs = Get-Content $VMFile |
       Where-Object {$_.Trim() -ne ""}



# ===============================
# Function - Network Status
# ===============================


function Get-NicAcceleration {


    param(

        [string]$RGName,
        [string]$VMName

    )


    try {


        $VM = Get-AzVM `
            -ResourceGroupName $RGName `
            -Name $VMName



        $NICID = $VM.NetworkProfile.NetworkInterfaces.Id



        $NICName = $NICID.Split("/")[-1]



        $NIC = Get-AzNetworkInterface `
            -ResourceGroupName $RGName `
            -Name $NICName



        return $NIC.EnableAcceleratedNetworking


    }

    catch {

        return "NOT FOUND"

    }


}



# ===============================
# STATUS
# ===============================


function Show-Status {


    Clear-Host


    Write-Host ""
    Write-Host "Azure VM Network Accelerator Status"
    Write-Host "================================================"


    foreach($VM in $VMs) {


        $acc = Get-NicAcceleration $RG $VM


        $power = (
            Get-AzVM `
            -ResourceGroupName $RG `
            -Name $VM `
            -Status
        ).Statuses |
        Where-Object {$_.Code -like "PowerState/*"} |
        Select-Object -ExpandProperty DisplayStatus



        if($acc -eq $true){


            Write-Host (
            "{0,-25} {1,-20} AcceleratedNetworking ENABLED" `
            -f $VM,$power
            ) -ForegroundColor Green


        }
        elseif($acc -eq $false){


            Write-Host (
            "{0,-25} {1,-20} AcceleratedNetworking DISABLED" `
            -f $VM,$power
            ) -ForegroundColor Yellow


        }
        else{


            Write-Host (
            "{0,-25} {1}" `
            -f $VM,$acc
            ) -ForegroundColor Red


        }


    }


    Write-Host "================================================"

}



# ===============================
# ENABLE NETWORK ACCELERATION
# ===============================


if($Action -eq "enable"){


    Write-Host ""
    Write-Host "Checking VMs..." -ForegroundColor Cyan



    foreach($VM in $VMs){


        $Current =
        Get-NicAcceleration $RG $VM



        if($Current -eq $true){


            Write-Host "$VM already enabled" `
            -ForegroundColor Green


        }


        elseif($Current -eq $false){


            Write-Host "Enabling acceleration on $VM" `
            -ForegroundColor Yellow



            $VMObj =
            Get-AzVM `
            -ResourceGroupName $RG `
            -Name $VM



            $NICID =
            $VMObj.NetworkProfile.NetworkInterfaces.Id



            $NICName =
            $NICID.Split("/")[-1]



            $NIC =
            Get-AzNetworkInterface `
            -ResourceGroupName $RG `
            -Name $NICName



            $NIC.EnableAcceleratedNetworking = $true



            Set-AzNetworkInterface `
            -NetworkInterface $NIC



            Write-Host "$VM enabled successfully" `
            -ForegroundColor Green


        }


    }


    Write-Host ""
    Write-Host "Final Validation"
    Write-Host "================================================"


    foreach($VM in $VMs){


        $status =
        Get-NicAcceleration $RG $VM



        Write-Host (
        "{0,-30} AcceleratedNetworking : {1}" `
        -f $VM,$status
        )


    }


}



# ===============================
# STATUS MODE
# ===============================


if($Action -eq "status"){

    Show-Status

}
