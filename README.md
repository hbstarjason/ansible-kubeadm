## **一、软件栈信息：**

| 软件名称                | 版本              | 备注                                     |
| ----------------------- | ----------------- | ---------------------------------------- |
| 宿主机操作系统：windows | windows 10 专业版 | 内存 > 8G+                               |
| 虚拟机操作系统：ubuntu  | ubuntu 16.04.5    | 自动安装                                 |
| VirtualBox              | v5.2.22           | https://www.virtualbox.org/              |
| Vagrant                 | v2.2.2            | https://www.vagrantup.com/downloads.html |
| Ansible                 | v2.7.5            | 自动安装                                 |
| kubeadm                 | v1.13.2           | 自动安装                                 |
| kubernetes              | v1.13.2           | 自动安装                                 |
| docker                  | 17.03.3-ce        | 自动安装                                 |

## **二、kubernetes集群信息：**

|    节点ip    | 节点名称 | 节点角色 | 备注                                                         |
| :----------: | :------: | :------: | :----------------------------------------------------------- |
| 192.16.35.12 |  k8s-m1  |  master  | kube-apiserver，kube-controller-manager，kube-scheduler，kube-proxy，etcd，coredns，calico-node，calico-kube-controllers，calico-etcd |
| 192.16.35.11 |  k8s-n2  |  node2   | calico-node，kube-proxy                                      |
| 192.16.35.10 |  k8s-n1  |  node1   | calico-node，kube-proxy                                      |

## **三、操作步骤：**

1、先安装好VirtualBox和Vagrant。

2、下载仓库代码，并进入代码目录，并且下载虚拟机模板文件放入代码目录中。

```
# 仓库地址
https://github.com/hbstarjason/ansible-kubeadm.git

# 虚拟机模板文件下载地址
https://vagrantcloud.com/bento/boxes/ubuntu-16.04/versions/201812.27.0/providers/virtualbox.box
```

3、启动脚本，一键自动化安装。等待ing……

```
# win+R快捷键，输入cmd回车，调出命令行，切换至代码目录
C:\Users\zhang>d:
D:\>cd kubeadm-ansible-master
D:\kubeadm-ansible-master>

# 添加本地虚拟机模板，并启动脚本，一键自动安装kubernetes集群
D:\kubeadm-ansible-master>vagrant box add virtualbox.box --name bento/ubuntu-16.04
D:\kubeadm-ansible-master>vagrant up
```

4、验证kubernetes集群。

```
# 登陆进去master
D:\kubeadm-ansible-master>vagrant ssh k8s-m1
vagrant@k8s-m1:~$
```

```
# 配置kubectl
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 或者执行脚本
vagrant@k8s-m1:~$ sh /vagrant/hack/init-kubectl.sh
```

```
# 查看集群信息
vagrant@k8s-m1:~$ kubectl get node
NAME     STATUS   ROLES    AGE   VERSION
k8s-m1   Ready    master   57m   v1.13.2
k8s-n1   Ready    <none>   53m   v1.13.2
k8s-n2   Ready    <none>   53m   v1.13.2

vagrant@k8s-m1:~$ kubectl cluster-info
Kubernetes master is running at https://192.16.35.12:6443
KubeDNS is running at https://192.16.35.12:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

5、使用浏览器登陆原生Dashboard：

浏览器访问：https://192.16.35.12:30000

获取访问token：

```
$ sh /vagrant/hack/get-dashboard-token.sh
```

6、清除整个环境

```
$ ansible-playbook reset-site.yaml
```

## **四、还存在一些问题：**

​       主体代码来自于：https://github.com/kairen/kubeadm-ansible/，在这个基础上做了一些优化和修改，以适应在天朝局域网内能愉快的玩耍，据不完全统计，修改的文件列表如下：

- Vagrantfile
- hack/setup-vms.sh
- group_vars/all.yml
- roles/commons/pre-install/tasks/pkg.yml
- roles/kubernetes/master/tasks/init.yml
- roles/docker/tasks/pkg.yml
- roles/docker/templates/daemon.json.j2



不过，还存在以下一些问题：

1. master为单节点，不是高可用。
2. 使用centos7为虚拟机镜像模板时，自动脚本在设置免密登陆时会有报错，然后终止掉脚本，不过登陆进入虚拟机，手动执行脚本也能完成整个集群的安装。因此，虚拟机镜像模板现在选用的是ubuntu16。
3. ~~会自动安装原生的dashboard，但是所需镜像（k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1）无法下载，导致dashboard暂时无法启动，等待修复中。~~【**已修复**】
4. 会考虑实现自动化安装更多插件和工具，如Ingress，Promethues，Helm，Istio等。



**原生Dashboard登陆问题：**

​     Windows下Chrome/Firefox访问，如果提示`NET::ERR_CERT_INVALID`，点高级无法跳过时，则需要下面的步骤：

```
$ cd ~/  && mkdir certs
$ openssl req -nodes -newkey rsa:2048 -keyout certs/dashboard.key -out certs/dashboard.csr -subj "/C=/ST=/L=/O=/OU=/CN=kubernetes-dashboard"
$ openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
$ kubectl delete secret kubernetes-dashboard-certs -n kube-system
$ kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
$ kubectl delete pods $(kubectl get pods -n kube-system|grep kubernetes-dashboard|awk '{print $1}') -n kube-system   #重新创建dashboard

# 或者直接执行脚本
vagrant@k8s-m1:~$ sh /vagrant/hack/repair-dashboard-login.sh
```

刷新浏览器之后点击`高级`，选择跳过即可打开页面。