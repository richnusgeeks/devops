#! /bin/bash
set -u

disks=$(find /dev -regex '/dev/\(xv\|s\)d[b-e]')

eval pvcreate $disks
pvdisplay
eval vgcreate vg_data $disks
vgdisplay
lvcreate -l 100%FREE -n lv_data vg_data
lvdisplay

mkfs.xfs /dev/vg_data/lv_data
echo "/dev/vg_data/lv_data /mnt xfs defaults,nobootwait,noatime 0 0" >>/etc/fstab
mount -a
df -kh
ln -s /mnt /raid0
ls -lhrt /
