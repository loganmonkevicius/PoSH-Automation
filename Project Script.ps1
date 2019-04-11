#make array as a list to pull from
   $vmnames = @(
    'THEDC',
    'MYCHILD',
    'MC2',
    'MC3'
)

#This line states that the "$vmstoragepath" variable will be the desktop for all of the VMs. 
 $vmstoragepath = "C:\Users\wwstudent\Desktop"


#Tell the system that the variable "vmname" will be pulled and applied from the list known as "$vmnames"
foreach ($vmname in $vmnames)
{
    #states that if you run "test-path" for a path that leads to the hard disk of a VM, and it already exists, to continue with the setup process. If it does not exist, it directs the script to the creation of a VM and VHD with the values we've given it.  
    if (test-path "$vmstoragepath\$vmname.vhdx")
    {
        continue
    }
    else
    {
        #This line adds the new VM, path, the switch it works on, memory, generation, virtual hard disk, and VHD size. Notices it uses the variables we've made previously. 

        $vm = New-VM -Name $vmname -path "$vmstoragepath\$vmname" -SwitchName "Default Switch" -Generation 2 -MemoryStartupBytes 3gb -NewVHDPath "$vmstoragepath\$vmname.vhdx" -NewVHDSizeBytes 20gb

        #Here you add the iso file that contains your operating system
     
        Add-VMDvdDrive -path C:\Users\wwstudent\Downloads\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO -vmname $vmname
    }
}

foreach ($VMname in $vmnames)
{
    $isopath = Get-VMDvdDrive -vmname $vmname
    $harddiskdrive = Get-VMHardDiskDrive -vmname $vmname
    $ide = Get-VMNetworkAdapter -vmname $vmname
    get-vmfirmware -vmname $vmname | set-vmfirmware -bootorder $isopath, $harddiskdrive, $ide
}

    ############### AT THIS POINT YOU CAN EITHER CONNECT TO YOUR VM AND MANUALLY CONFIGURE YOUR OS OR YOU CAN USE AN XML FILE TO AUTOMATE TO YOUR SPECIFICATIONS ################

foreach ($VMname in $vmnames)
{
    $isopath = Get-VMDvdDrive -vmname $vmname
    $harddiskdrive = Get-VMHardDiskDrive -vmname $vmname
    $ide = Get-VMNetworkAdapter -vmname $vmname
    get-vmfirmware -vmname $vmname | set-vmfirmware -bootorder $harddiskdrive, $isopath, $ide
}

#Connect to THEDC
Start-VM -vmname THEDC
Enter-PSSession -VMName THEDC

#automate credentials#

#setting static IP
Get-NetIPInterface
New-NetIPAddress -IPAddress 192.168.0.2 -DefaultGateway 192.168.0.1 -PrefixLength 24 -InterfaceAlias Ethernet

#installing ADDS and upgrading to domain controller
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature dns -IncludeManagementTools
Install-ADDSForest -DomainName ShawnLogan.com -InstallDNS

#disable firewall
Set-NetFirewallProfile -profile domain, public, private -Enabled False

#Connect to MYCHILD
Start-VM -vmname MYCHILD
Enter-PSSession -VMName MYCHILD

#setting static IP
Get-NetIPInterface
New-NetIPAddress -IPAddress 192.168.0.3 -DefaultGateway 192.168.0.1 -PrefixLength 24 -InterfaceAlias Ethernet

#disable firewall
Set-NetFirewallProfile -profile domain, public, private -Enabled False

#add to domain
add-computer -domainname ShawnLogan.com
exit
Restart-VM -vmname MYCHILD
