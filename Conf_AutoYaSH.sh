#׼������ص������ļ�
#1��dhcpd.conf   -- DHCP�����ļ�
#2��message      -- Linux��������������ʾ�ļ�
#3��default      -- ���� x86 �� BIOS �����������������ļ�
#4��grub.cfg     -- ���� x86 �� UEFI �ļ��������������ļ�
#5��autoinst.xml -- AutoYast ���óɹ������ɿ��Ʋ���ϵͳ��װ XML �����ļ� 
today=$(date "+%Y%m%d")


#��װ��ص�ģ��
instModule {
	zypper install -y dhcp*
	zypper install -y tftp
	zypper install -y vsftpd
#syslinux���ṩ��һ���ǳ����õ��ļ�:/usr/share/syslinux/pxelinux.0	
	zypper install -y syslinux
}
#���� DHCP ����

#����ISO�ļ���mount����ܱ���
MountISO{
	mkdir -p /srv/install/x86/sles12/sp0/cd1
	mount  -o loop -t iso9660 /install/iso/SLE-12-Server-DV.iso /srv/install/x86/sles12/sp0/cd1/
  /srv/install/x86/sles12/sp0/cd1/
}

#������ص��ļ�ϵͳ
BackupFile {
	cp /etc/dhcpd.conf ./dhcpd.conf.$today.bak
	cp -f /srv/install/x86/sles12/sp0/cd1/boot/x86_64/loader/message ./message.$today.bak
  cp -f /srv/install/x86/sles12/sp0/cd1/boot/x86_64/loader/isolinux.cfg ./default.$today.bak
  cp -f /srv/install/x86/sles12/sp0/cd1/EFI/BOOT/grub.cfg ./grub.cfg.$today.bak
  cp -f /root/autoinst.xml ./autoinst.xml.$today.bak
}

confDHCP {
	cp -f dhcpd.conf /etc/dhcpd.conf
#����DHCP����
  yast dhcp-server
}
#ʹ�� YaST ����NFS��װ������
confNFS {
#����Ŀ¼Ϊ/srv/install/x86/sles12/sp0/ + #����Ŀ¼Ϊ/srv/install/x86/sles12/sp0/cd1/
  yast instserver
  cp -f autoinst.xml /srv/install/x86/sles12/sp0/
  showmount -e localhost
}
#ʹ�� YaST ���� TFTP ������
confTFTP {
	yast tftp-server
#�� /srv/tftpboot �д���һ���ṹ��֧�ָ���ѡ��
#���� 64 λ UEFI �̼��� PC���� UEFI ����ģʽ��ֻ������ 64 λ����ϵͳ��������
#�� Legacy ����ģʽ���� BIOS ���ݿ���ģʽ���£�ͨ�������ֲ���ϵͳ�ı�����
#����� Linux ���а���ʹ�� GRUB ��Ϊ UEFI �µ���������
mkdir -p /srv/tftpboot/BIOS/x86
mkdir -p /srv/tftpboot/BIOS/x86/pxelinux.cfg
mkdir -p /srv/tftpboot/EFI/x86/boot
mkdir -p /srv/tftpboot/EFI/aarch64/boot
mkdir -p /srv/install/aarch64/sles12/sp0/cd1
}

confBOOT {
#�� x86 BIOS �� UEFI ��������� kernel �� initrd �� message �ļ����Ƶ���Ӧ��λ��
#Linux������������linux�ں�(linux�������ļ�) + ���ļ�ϵͳ(initrd�������ļ���+������ʾ��Ϣ(message)
cd /srv/install/x86/sles12/sp0/cd1/boot/x86_64/loader/ && cp -a linux initrd message /srv/tftpboot/BIOS/x86/
cd /srv/install/x86/sles12/sp0/cd1/boot/x86_64/loader/ && cp -a linux initrd /srv/tftpboot/EFI/x86/boot
cp -f message /srv/tftpboot/BIOS/x86/message
}

#���� x86 �� BIOS
#PXE������������(Bootstrap file��pxelinux.0)+�����˵�������(pxelinux.cfg�ļ����µ�default�ļ�)
#�����˵�������default������ 2 ����Ҫ���ļ���linux��initrd��
#�� pxelinux.0 ���Ƶ� TFTP �ļ��в�Ϊ�����ļ�׼��һ�����ļ���
confBIOS {
	cp /usr/share/syslinux/pxelinux.0 /srv/tftpboot/BIOS/x86/
# cp /srv/install/x86/sles12/sp0/cd1/boot/x86_64/loader/isolinux.cfg /srv/tftpboot/BIOS/x86/pxelinux.cfg/default
  cp -f default /srv/tftpboot/BIOS/x86/pxelinux.cfg/default
}

#���� x86 �� UEFI �ļ�
#���� UEFI ������������� grub2 �ļ�(bootx64.efi + grub.efi + MokManager.efi)
#���ں˺� initrd �ļ����Ƶ�Ŀ¼�ṹ(linux + initrd)
confUEFI {
	cd /srv/install/x86/sles12/sp0/cd1/EFI/BOOT && cp -a bootx64.efi grub.efi MokManager.efi /srv/tftpboot/EFI/x86/
# cp /srv/install/x86/sles12/sp0/cd1/EFI/BOOT/grub.cfg /srv/tftpboot/EFI/x86/grub.cfg
  cp -f grub.cfg /srv/tftpboot/EFI/x86/grub.cfg
}

#���� AARCH64 �� UEFI �ļ�
#���� UEFI ������������� grub2 �ļ�(bootx64.efi + grub.efi + MokManager.efi)
#���ں˺� initrd �ļ����Ƶ�Ŀ¼�ṹ(linux + initrd)
confAARCH64 {
	cd /srv/install/aarch64/sles12/sp0/cd1/EFI/BOOT && cp -a bootaa64.efi /srv/tftpboot/EFI/aarch64/
# cp /srv/install/x86/sles12/sp0/cd1/EFI/BOOT/grub.cfg /srv/tftpboot/EFI/x86/grub.cfg
  cp -f grub.cfg /srv/tftpboot/EFI/x86/grub.cfg
}


#������Ϊ��Ҫ��װϵͳ�Ļ��� �����������������ý� PXE ѡ������� BIOS ����������
#1����˶���壺BIOS--�߼�--�����豸--Realtek PXE OPROM