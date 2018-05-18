#! /bin/bash
set -u

disks=$(find /dev -regex '/dev/\(xv\|s\)d[b-e]')
devs=$(echo -e "$disks"|wc -l)
umount $disks
for disk in $disks; do
	name=$(echo $disk|sed -e 's/.*\///')
	sed -i "/$name/d" /etc/fstab
	echo -e "d\\nn\\np\\n1\\n\\n\\nt\\nfd\\nw" | fdisk $disk
done

if [ "$devs" -gt "1" ];then
	parts=$(find /dev -regex '/dev/\(xv\|s\)d[b-e]1')
	mdadm --stop /dev/md0
	echo yes | mdadm --create /dev/md0 --level=0 --chunk=256 --raid-devices=$devs $parts
	echo DEVICE $parts > /etc/mdadm/mdadm.conf | mdadm --detail --scan >> /etc/mdadm/mdadm.conf
	update-initramfs -u
	sed -i "/md0/d" /etc/fstab
	mkfs.xfs -q -f /dev/md0; mkdir -p /raid0;
	echo "/dev/md0 /raid0 xfs defaults,nobootwait,noatime 0 0" >>/etc/fstab
	mount /raid0
else
	mkfs.xfs -q -f ${disk}1; mkdir -p /mnt;
	echo "${disk}1 /mnt xfs defaults,nobootwait,noatime 0 0" >>/etc/fstab
	mount /mnt
	ln -s /mnt /raid0
fi

