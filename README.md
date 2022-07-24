# About

This repository contains the installation procedure of the Drakvuf, A VMI based black-box malware analysis tool. Drakvuf allows the execution of the malware binaries without using any third party tools. It uses the XEN Hypervisor which is installed in the DOM0 environment and Analysis part of the malware is done in the DOM1, DOM2 and so on.

# Drakvuf Installation

Drakvuf is a black box binary dynamic malware analysis tool. It works on the principle of the VMI (Virtual Machine Introspection).

1. Make sure to disable the "Secure Boot" from the BIOS.
2. While Installating the ubuntu make at least 200 GB space free for LVM group.

## Installation

## Operating System Configuration

- Before installing the drakvuf you have to make partition in the system for the LVM and system space.

![Installation](/1.png)
- Make sure to check the all boxes as pe the below image before proceeding furthur. However it not mandatory but still it helps to install the latest verison of software.

![Installation](/2.png)

- In Installation type, select the Something else.

![Installation](/3.png)

- If you already have some installed lvm partition you run the following command to delete it.

![Installation](/4.png)

- Now create the swap space, efi space and the main system space for DOM0 XEN installation.

![Installation](/5.png)

- Click on the Install button.

![Installation](/6.png)
## Dependencies and Packages Installation

These commands works fine with Debian based linux distro. We have used the Ubunut 20.04 Focal Fossa operting system. First isnstall the required dependencies.

First Update your linux system:

```bash
  sudo apt update
  sudo apt udgrade -y
```

Now install the required Dependencies.

```bash
  sudo apt-get install wget git bcc bin86 gawk bridge-utils iproute2 libcurl4-openssl-dev bzip2 libpci-dev build-essential make gcc clang libc6-dev linux-libc-dev zlib1g-dev libncurses5-dev patch libvncserver-dev libssl-dev libsdl-dev iasl libbz2-dev e2fslibs-dev git-core uuid-dev ocaml libx11-dev bison flex ocaml-findlib xz-utils gettext libyajl-dev libpixman-1-dev libaio-dev libfdt-dev cabextract libglib2.0-dev autoconf automake libtool libjson-c-dev libfuse-dev liblzma-dev autoconf-archive kpartx python3-dev python3-pip golang python-dev libsystemd-dev nasm -y
```

pip3 command is used to install those dependency pakages which old and cannot be installed from apt command.

```bash
  sudo pip3 install pefile construct
```

## Cloning of Drakvuf from Official repository

Cloning the Drakvuf directory from the official Github Repository.

```bash
  cd ~
  git clone https://github.com/tklengyel/drakvuf
  cd drakvuf
  git submodule update --init
  cd xen
  ./configure --enable-githttp --enable-systemd --enable-ovmf --disable-pvshim
  make -j4 dist-xen
  sudo apt-get install -y ninja-build
  make -j4 dist-tools
  make -j4 debball
```

## XEN Installation

Now we have to install Xen with dom0 getting 4GB RAM assigned and two dedicated CPU cores. You can modify these configuration according to your need. At last update the Grub and reboot the system.

```bash
  sudo su
  apt-get remove xen* libxen*
  dpkg -i dist/xen*.deb
  echo "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=4096M,max:4096M dom0_max_vcpus=4 dom0_vcpus_pin=1 force-ept=1 ept=ad=0 hap_1gb=0 hap_2mb=0 altp2m=1 hpet=legacy-replacement smt=0\"" >> /etc/default/grub
  echo "/usr/local/lib" > /etc/ld.so.conf.d/xen.conf
  ldconfig
  echo "none /proc/xen xenfs defaults,nofail 0 0" >> /etc/fstab
  echo "xen-evtchn" >> /etc/modules
  echo "xen-privcmd" >> /etc/modules
  systemctl enable xen-qemu-dom0-disk-backend.service
  systemctl enable xen-init-dom0.service
  systemctl enable xenconsoled.service
  update-grub
```

Note: Make sure that you are running a relatively recent kernel. In Ubuntu 20.04 the 5.10.0-1019-oem kernel has been verified to work, anything newer would also work. Older kernels in your dom0 will not work properly.

```bash
  uname -r
```

After above step make the XEN to boot before the linux kernal.

```bash
  cd /etc/grub.d/;
  mv 20_linux_xen 09_linux_xen
```

Update the changes in the Grub and reboot the system.

```bash
  update-grub
  reboot
```

Verify the XEN installation. The output will show the "Running in PV context on Xen v4.7" message on the screen

```
  sudo xen-detect
```

This command will list the running VM.

```bash
  sudo xl list
```

The output should have to be similar to this.

```bash
Name                                        ID   Mem    VCPUs 	 State	 Time(s)
Domain-0                                       0  4096     2       r-----    614.0
```

## Logical Volume Manager(LVM Setup and Installation)

First install the lvm2

```bash
  sudo apt-get install lvm2 -y
```

Note: Before creating physical volume (PV), Go inside Disk partition and create a volume. Never give the whole path of disk like /dev/sda otherwise your os will be crashed down. So when you will create a volume then it has named like /dev/sd2 or /dev/sd3 and so on. So pick only a free volume then move ahead.

List the empty disk using the following command:

```bash
  lsblk
```

Create physical volume. Hera "sda" is disk volume, it can vary accordingly.

```bash
  pvcreate /dev/sda2
```

Create one volume Group.

```bash
  vgcreate vg /dev/sda2
```

Create logical volume group. You can specify the size, here we allocating 110 GB space, you can change it by altering the the size of '110'.

```bash
  lvcreate -L110G -n windows7-sp1 vg
```

## Install the VMM Utility tool And Networking tool.

Now Install the VMM utility from the ubuntu software software

## Newtworking Configuration

Now install the networking tool.

Next we need to set up our system so that we can attach virtual machines to the external network. This is done by creating a virtual switch within dom0. The switch will take packets from the virtual machines and forward them on to the physical network so they can see the internet and other machines on your network.

The piece of software we use to do this is called the Linux bridge and its core components reside inside the Linux kernel. In this case, the bridge acts as our virtual switch. The Debian kernel is compiled with the Linux bridging module so all we need to do is install the control utilities:

```bash
  $sudo apt-get install bridge-utils
```

Management of the bridge is usually done using the brctl command. The initial setup for our Xen bridge, though, is a "set it once and forget it" kind of thing, so we are instead going to configure our bridge through Debian’s networking infrastructure. It can be configured via /etc/network/interfaces.

Open this file with the editor of your choice. If you selected a minimal installation, the nano text editor should already be installed. Open the file:

Note: nano is a text file editor for linux. You can also use the vi, vim editor also. If command show error then run "sudo apt install nano -y"

```bash
  $sudo nano /etc/network/interfaces      //open the interface file
```

This file is very simple. Each stanza represents a single interface.

Breaking it down,

1. “auto eth0” meeans that eth0 will be configured when ifup -a is run (which happens at boot time). This means that the interface will automatically be started/stopped for you. ("eth0 is its traditional name - you'll probably see something more current like "ens1", "en0sp2" or even "enx78e7d1ea46da")

2. “iface eth0” then describes the interface itself. In this case, it specifies that it should be configured by DHCP - we are going to assume that you have DHCP running on your network for this guide. If you are using static addressing you probably know how to set that up.

We are going to edit this file so it resembles such:

Note: Change according to your network interface (run “ifconfig”).

Copy the following text and paste it in the interfaces files.

```bash
  auto lo
  iface lo inet loopback

  auto enp1s0
  iface enp1s0 inet manual

  auto virbr0
  iface virbr0 inet dhcp
       bridge_ports enp1s0
```

Make sure to add the bridge stanza, be sure to change dhcp to manual in the iface eth0 inet manual line, so that IP (Layer 3) is assigned to the bridge, not the interface. The interface will provide the physical and data-link layers (Layers 1 & 2) only.

Restart the Networking service.

```bash
  sudo service network-manager restart
```

Now turn on the network bridge service.

```bash
  $sudo gedit /etc/NetworkManager/NetworkManager.conf
  manages = true  //make true from false
  $service network-manager restart
```

To show network Vm interfaces.

```bash
  brctl show
```

The output will show something like this.

```bash
  bridge name     bridge id               STP enabled     interfaces
  virbr0          8000.4ccc6ad1847d       yes              virbr0-nic
```

The networking service can now be set to start automatically whenever the system is rebooted. Please review the installation instructions once again if you are having trouble getting this type of output.

## Download link for windows 7 iso:

Before proceeding furthur we need 64-bit windows 7 iso image. You can download from anywhere or can find the already tested image from [Here](https://drive.google.com/drive/folders/1dWSDHGIdmVdWbnbU3AfEzrsPCRPaCxam).

## VM Creation and Configuration

Next step is to edit the xen VM's configuration file.

```bash
  $ sudo gedit /etc/xen/win7.cfg
```

This template is used for creating the Configurtion for Windows 7 VM from the download ISO file. You can modify the number of cpu, max memory, VM behaviour and other system tuning.
s

```bash
  rch = 'x86_64'
  name = "windows7-sp1"
  maxmem = 3000
  memory = 3000
  vcpus = 2
  maxvcpus = 2
  builder = "hvm"
  boot = "cd"
  hap = 1
  on_poweroff = "destroy"
  on_reboot = "destroy"
  on_crash = "destroy"
  vnc = 1
  vnclisten = "0.0.0.0"
  vga = "stdvga"
  usb = 1
  usbdevice = "tablet"
  audio = 1
  soundhw = "hda"
  viridian = 1
  altp2m = 2
  shadow_memory = 32
  vif = [ 'type=ioemu,model=e1000,bridge=virbr0,mac=48:9e:bd:9e:2b:0d']
  disk = [ 'phy:/dev/vg/windows7-sp1,hda,w', 'file:/home/pc-1/Downloads/windows7.iso,hdc:cdrom,r' ]
```

Note: Make changes according to your file path of windows iso image and mac address.

## Clone LibVMI and Installation

Now, Enter into the LibVMI folder and build it.

```bash
  cd ~/drakvuf/libvmi
  autoreconf -vif
  ./configure --disable-kvm --disable-bareflank --disable-file
```

Output of the above command should look something this:

```bash
  Feature         | Option
----------------|---------------------------
Xen Support     | --enable-xen=yes
KVM Support     | --enable-kvm=no
File Support    | --enable-file=yes
Shm-snapshot    | --enable-shm-snapshot=no
Rekall profiles | --enable-rekall-profiles=yes
----------------|---------------------------

OS              | Option
----------------|---------------------------
Windows         | --enable-windows=yes
Linux           | --enable-linux=yes


Tools           | Option                    | Reason
----------------|---------------------------|----------------------------
Examples        | --enable-examples=yes
VMIFS           | --enable-vmifs=yes        | yes
```

Build and install LibVMI

```bash
  make
  sudo make install
  sudo echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc
```

Other commands to run:

```bash
  cd ~/drakvuf/libvmi
  ./autogen.sh
  ./configure –disable-kvm
  sudo xl list
```

## Clone Volatility and Installation

```bash
  cd ~/drakvuf/volatility3
  python3 ./setup.py build
  sudo python3 ./setup.py install
```

Rekall Installation.

```bash
  cd ~/drakvuf/rekall/rekall-core
  sudo pip install setuptools
  python setup.py build
  sudo python setup.py install
```

## Create VM and Configure VM from DOM0

Last step of this configuration is to create Windows 7 VM using the following command.

```bash
  xl create /etc/xen/win7.cfg
```

In order to login into the virtual machine you have created, you first have to install the "gvncviewer".

```bash
  sudo apt install gvncviewer
```

## JSON File Creation using LibVMI vmi-win-guid tool and Volatility Framework

Now we will create the JSON configuration file for the Windows domain. First, we need to get the debug information for the Windows kernel via the LibVMI vmi-win-guid tool. For example, in the following my domain is named windows7-sp1.

```bash
  $ sudo xl list
Name                                        ID   Mem VCPUs	State	Time(s)
Domain-0                                     0  4024     4     r-----     848.8
windows7-sp1-x86                             7  3000     1     -b----      94.7
```

Get the debug information.

```bash
  $ sudo vmi-win-guid name windows7-sp1-x86
  Windows Kernel found @ 0x2604000
    Version: 32-bit Windows 7
    PE GUID: 4ce78a09412000
    PDB GUID: 684da42a30cc450f81c535b4d18944b12
    Kernel filename: ntkrpamp.pdb
    Multi-processor with PAE (version 5.0 and higher)
    Signature: 17744.
    Machine: 332.
    # of sections: 22.
     # of symbols: 0.
    Timestamp: 1290242569.
    Characteristics: 290.
    Optional header size: 224.
    Optional header type: 0x10b
    Section 1: .text
    Section 2: _PAGELK
    Section 3: POOLMI
    Section 4: POOLCODE
    Section 5: .data
    Section 6: ALMOSTRO
    Section 7: SPINLOCK
    Section 8: PAGE
    Section 9: PAGELK
    Section 10: PAGEKD
    Section 11: PAGEVRFY
    Section 12: PAGEHDLS
    Section 13: PAGEBGFX
    Section 14: PAGEVRFB
    Section 15: .edata
    Section 16: PAGEDATA
    Section 17: PAGEKDD
    Section 18: PAGEVRFC
    Section 19: PAGEVRFD
    Section 20: INIT
    Section 21: .rsrc
    Section 22: .reloc
```

Note: If found error in running the above commands, run following command then rerun the above command.

```bash
  sudo /sbin/ldconfig -v
```

Copy the following string from the terminal output

```bash
  PDB GUID: f794d83b0f3c4b7980797437dc4be9e71
	Kernel filename: ntkrnlmp.pdb
```

Now run the following commands from the by changing the paramater accordingly to create LibVMI config with Rekall profile:

```bash
cd /tmp
  python3 ~/drakvuf/volatility3/volatility/framework/symbols/windows/pdbconv.py --guid f794d83b0f3c4b7980797437dc4be9e71 -p ntkrnlmp.pdb -o windows7-sp1.json
  sudo mv windows7-sp1.json /root
```

Now generate the reakall profile.

```bash
  sudo su
  printf "windows7-sp1 {\n\tvolatility_ist = \"/root/windows7-sp1.json\";\n}" >> /etc/libvmi.conf
  exit
```

Now build the drakvuf using the following commands

```bash
  cd ~/drakvuf
  autoreconf -vi
  ./configure
  make
```

Run the following to get the PID's of the processes.

```bash
  sudo vmi-process-list windows7-sp1
```

Now login to Virtual Machine and install the windows with giving it login password.

```bash
  gvncviewer localhost
```

When the Windows Installation is finished, follow the following step.

1. Create a partition of 50G. (A seperate Disk drive)
2. Turn all the firewall off.
3. Create a restore point using the newely created partitoin (new drive) // Serach for “create a restore point” in windows start menu.
4. Goto My Computer --> Right click on new volume you have created --> Security --> provide the full control to all the users.

## Program Execution Tracing Log Generation using Drakvuf

- System tracing:

```bash
  sudo ./src/drakvuf -r /root/windows7-sp1.json -d id
```

Here, id of virtual machine (use sudo xl list command)

- Malware Tracing Command

```bash
  sudo ./src/drakvuf -r /root/windows7-sp1.json -d 1 -x socketmon -t 120 -i 1300 -e “E:\\zbot\\zbot_1.exe” > zbot_1.txt
```

Here,

1300 = change according to pid of explorer.exe
1= id of virtual machine (use sudo xl list command)
“E:\\zbot\\zbot_1.exe”= Location of malware ".exe" file in the created windows VM.
zbot_1.txt= Location of the output file. By default is drakvuf location.

- Network Tracing

```bash
  ping -n 10000 www.google.com  (from cmd of VM)
  sudo tcpdump -w "zbot_1.pcap" -i vif1.0-emu   (can be obtained from brctl show)
```

#### Other Commmands

Xen version:

```bash
  sudo xen-detect
```

List of VMs:

```bash
  sudo xl list
```

Destroy VM:

```bash
  sudo xl destroy id
```

VM boot:

```bash
  gvncviewer localhost
```

CREATE VM:

```bash
  sudo xl create /etc/xen/win7.cfg
```

Windows json file:

```bash
  sudo vmi-win-guid name windows7-sp1
```

VMI process list:

```bash
  sudo vmi-process-list windows7-sp1
```

Enabling the debug:

```bash
  make clean
  ./configure --enable-debug
  make
```

Debug output: (With process injection)

```bash
sudo ./src/drakvuf -r /root/windows7-sp1.json -d 1 -x socketmon -t 120 -i 1300 -e “E:\\zbot\\zbot_1.exe” -v 1> zbot_1.txt
```

Note: Retype all the quotes from the keyboard in the terminal before running the command
Here,

1300 = change according to pid of explorer.exe
1= id of virtual machine (use sudo xl list command)
