
ken(){

if [ -f /etc/redhat-release ];then
    yum -y update
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
        if [ $? -eq 0 ];then
        echo "导入源成功开始升级"
        yum --enablerepo=elrepo-kernel install kernel-lt -y 
            else
                echo "导入错误"
                exit 1
        fi
            if [ $? -eq ];then
                grub2-set-default 0
                else
                echo "安装错误"
                exit 1
            fi
    else
        echo "错误系统"
        exit 1
fi
}
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
ken
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg