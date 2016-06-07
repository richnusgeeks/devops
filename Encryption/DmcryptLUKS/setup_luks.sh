#! /bin/bash
set -u

RAID0=true
KEYLEN='4K'
LR0MDN='data'
LUKSKEY='luks.key'
RAID0DEV='/dev/md0'
FSTAB='/etc/fstab'
CRYPTTAB='/etc/crypttab'
disks=$(find /dev -regex '/dev/\(xv\|s\)d[b-e]')
devs=$(echo -e "$disks"|wc -l)

exitOnErr() {
  local date=$(date)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

preChecks() {

  for c in lvm mdadm cryptsetup
  do
    if ! which "$c" 2>/dev/null
    then
      if [ "$c" = "lvm" ] && ! $RAID0
      then
        exitOnErr "required lvm command not found"
      elif [ "$c" = "mdadm" ] && $RAID0
      then
        exitOnErr "required mdadm command not found"
      else
        exitOnErr "required $c command not found"
      fi
    fi
  done

}

removeRAID0() {

  if $RAID0
  then
    if ! umount "$RAID0DEV"
    then
      exitOnErr "umount $RAID0DEV failed"
    else
      sed -i "/$(basename "$RAID0DEV")/d" "$FSTAB"
    fi

    if ! mdadm -S "$RAID0DEV"
    then
      exitOnErr "mdadm -S $RAID0DEV failed"
    else
      sleep 5
    fi
  fi

}

removeLVM() {

  if ! $RAID0
  then
    lvpath=$(lvdisplay 2>/dev/null|grep '^ *LV Path'|awk '{print $3}')
    vgname=$(vgdisplay 2>/dev/null|grep '^ *VG Name'|awk '{print $3}')
    if [ ! -z "$lvpath" ] && ! umount "$lvpath"
    then
      exitOnErr "umount $lvpath failed"
    else
      sleep 5
      if [ ! -z "$vgname" ] && ! vgremove -f "$vgname"
      then
        exitOnErr "vgremove -f $vgname failed"
      fi
    fi

    if [ ! -z "$vgname" ]
    then
      sed -i "/$vgname/d" "$FSTAB"
    fi
  fi

}

setupRAID0() {

  if $RAID0
  then
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
    fi
    sleep 10
  fi

}

setupLUKS() {

  dd if=/dev/urandom of="/$LUKSKEY" bs="$KEYLEN" count=1 > /dev/null 2>&1 || \
   exitOnErr 'random LUKS key creation failed'

  if ! $RAID0
  then
    umount $disks
    for disk in $disks; do
      name=$(echo $disk|sed -e 's/.*\///')
      sed -i "/$name/d" /etc/fstab
    done
  fi

  if $RAID0
  then
    cryptsetup -q luksFormat --cipher aes-cbc-essiv:sha256 \
     --hash ripemd160 --key-size 256 "$RAID0DEV" "/$LUKSKEY" || \
     exitOnErr "luks partition creation on $RAID0DEV failed"

    cryptsetup luksOpen --key-file "/$LUKSKEY" "$RAID0DEV" "$LR0MDN" || \
     exitOnErr "luks partition opening on /dev/mapper/$LR0MDN failed"

    if ! grep "$LR0MDN UUID=$(sudo cryptsetup luksUUID "$RAID0DEV") /$LUKSKEY luks" "$CRYPTTAB" > /dev/null 2>&1
    then
      sed -i "/$LR0MDN/d" "$CRYPTTAB"
      echo "$LR0MDN UUID=$(sudo cryptsetup luksUUID "$RAID0DEV") /$LUKSKEY luks"| \
       sudo tee -a "$CRYPTTAB" || \
       exitOnErr "appending entry for $LR0MDN to $CRYPTTAB failed"
    fi
  else
    for disk in $disks
    do
      cryptsetup -q luksFormat --cipher aes-cbc-essiv:sha256 \
       --hash ripemd160 --key-size 256 "$disk" "/$LUKSKEY" || \
       exitOnErr "luks partition creation on $disk failed"

      cryptsetup luksOpen --key-file "/$LUKSKEY" "$disk" "luks$(basename "$disk")" || \
       exitOnErr "luks partition opening on /dev/mapper/luks$(basename "$disk") failed"

      if ! grep "luks$(basename "$disk") UUID=$(sudo cryptsetup luksUUID "$disk") /$LUKSKEY luks" "$CRYPTTAB" > /dev/null 2>&1
      then
        sed -i "/luks$(basename "$disk")/d" "$CRYPTTAB"
        echo "luks$(basename "$disk") UUID=$(sudo cryptsetup luksUUID "$disk") /$LUKSKEY luks"| \
         sudo tee -a "$CRYPTTAB" || \
         exitOnErr "appending entry for $LR0MDN to $CRYPTTAB failed"
      fi
    done
  fi

}

setupLVM() {

  if ! $RAID0
  then
    eval pvcreate $(echo $disks|sed 's/dev\/\([a-zA-Z0-9]\{1,\}\)/dev\/mapper\/luks\1/g') || \
     exitOnErr "pvcreate on LUKS devices failed"

    eval vgcreate vg_data $(echo $disks|sed 's/dev\/\([a-zA-Z0-9]\{1,\}\)/dev\/mapper\/luks\1/g') || \
     exitOnErr "vgcreate on LUKS devices failed"

    lvcreate -l 100%FREE -n lv_data vg_data || \
     exitOnErr "lvcreate on vg_data failed"
  fi

}

setupFLSYS() {

  mkdir -p "/$LR0MDN"

  if $RAID0
  then
    mkfs.xfs "/dev/mapper/$LR0MDN" && \
     echo "/dev/mapper/$LR0MDN /$LR0MDN" xfs defaults,nobootwait,noatime 0 0" >>/etc/fstab
  else
    mkfs.xfs /dev/vg_data/lv_data && \
     echo "/dev/vg_data/lv_data /$LR0MDN xfs defaults,nobootwait,noatime 0 0" >>/etc/fstab
  fi

  mount -a

}

dumpR0LLF() {

  df -kh
  echo
  mount
  echo

  if $RAID0
  then
    cryptsetup isLuks -v "$RAID0DEV"
    echo
    cryptsetup luksUUID "$RAID0DEV"
    echo
    cryptsetup luksDump "$RAID0DEV"
    echo
    cat /proc/mdstat
    echo
  else
    for disk in $disks; do
      cryptsetup isLuks -v "$disk"
      echo
      cryptsetup luksUUID "$disk"
      echo
      cryptsetup luksDump "$disk"
      echo
    done
    pvdisplay
    echo
    vgdisplay
    echo
    lvdisplay
    echo
  fi

  cat "$FSTAB"
  echo
  cat "$CRYPTTAB"
  echo

}

preChecks
removeRAID0
removeLVM
setupRAID0
setupLUKS
setupLVM
setupFLSYS
dumpR0LLF
