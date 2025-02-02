#########################################################################################
# SCENARIO 14.3: Trident configuration
#########################################################################################  

Now that the storage tenant is up & running, we can tell both Trident & Kubernetes to use it!  

```bash
$ kubectl create -n trident -f secret_ontap_nfs-secured.yaml
secret/ontap-nfs-secured-secret created

$ kubectl create -n trident -f backend-svm-secured-NFS.yaml
tridentbackendconfig.trident.netapp.io/backend-tbc-ontap-nas-secured created

$ kubectl create -n trident -f secret_ontap_iscsi-secured.yaml
secret/ontap-iscsi-secured-secret created

$ kubectl create -n trident -f backend-svm-secured-iSCSI.yaml
tridentbackendconfig.trident.netapp.io/backend-tbc-ontap-san-secured created
```

Trident now has 2 new secured backends! Let's create some storage classes in Kubernetes:

```bash
$ kubectl create -f sc-svm-secured-nas.yaml
storageclass.storage.k8s.io/sc-svm-secured-nas created

$ kubectl create -f sc-svm-secured-san.yaml
storageclass.storage.k8s.io/sc-svm-secured-san created

$ kubectl get sc
NAME                          PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
sc-svm-secured-nas            csi.trident.netapp.io   Delete          Immediate           true                   39s
sc-svm-secured-san            csi.trident.netapp.io   Delete          Immediate           true                   31s
```

If you want a quick way to try out both new backends, you can use the following Ghost configurations:

- _RWX File_ Ghost exposed on port 30980
- _RWO Block_ Ghost exposed on port 30981

```bash
$ kubectl create namespace ghost-nas-secured
namespace/ghost-nas-secured created

$ kubectl create -n ghost-nas-secured -f Ghost_NAS/
persistentvolumeclaim/blog-content created
deployment.apps/blog created
service/blog created

$ kubectl create namespace ghost-san-secured
namespace/ghost-san-secured created

$ kubectl create -n ghost-san-secured -f Ghost_SAN/
persistentvolumeclaim/blog-content created
deployment.apps/blog created
service/blog created
```

Great, our secured environment is working!  
However, let's look at what we can mount on a host (_rhel5_), ie outside of the Kubernetes cluster:  

```bash
$ mkdir /mnt/test
$ mount -t nfs 192.168.0.211:/ /mnt/test/
$ ls -la /mnt/test/
ls: cannot access test/sec_pvc_54321cf6_469a_432d_b30b_6b430088a3cd: Permission denied
total 8
drwxr-xr-x  4 root root 4096 Oct 25 16:14 .
drwxr-xr-x. 4 root root   28 Oct 25 17:14 ..
??????????? ? ?    ?       ?            ? sec_pvc_54321cf6_469a_432d_b30b_6b430088a3cd
drwxrwxrwx  3 root root 4096 Oct 25 17:05 .snapshot
$ umount /mnt/test
```

We can still see the name of the NAS PVC ! (the SAN volume is not connected to any export policy)...  

As said in the first part of this scenario, the root volume is exported with a policy that is too open (192.168.0.0/24 in this case).  
That is simply because at the time of the storage tenant creation, Trident had not yet been configured.  
We should definitely assign it the policy created by Trident, which is dynamic & will evolve alongside the Kubernetes cluster.  

Another Ansible playbook will be used to perform this task (assuming the SVM only has one export policy dynamically managed by Trident).  

```bash
$ ansible-playbook svm_secured_export_policy.yaml
PLAY [Set Export Policy on Tenant Root]
TASK [Gathering Facts]
TASK [Gather Tenant Export Policy information]
TASK [Modify root Export Policy]
PLAY RECAP
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Protection applied!  
Let's try again to mount the storage tenant root volume on _rhel5_:

```bash
$ mount -t nfs 192.168.0.211:/ /mnt/test/
mount.nfs: access denied by server while mounting 192.168.0.211:/
```

DONE !

## What's next

You can now move on to:

- [Scenario15](../../Scenario15): CSI Topology Management

You can fo back to the [GitHub FrontPage](https://github.com/YvosOnTheHub/LabNetApp)