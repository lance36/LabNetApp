#########################################################################################
# SCENARIO 7#2: Import a Block volume
#########################################################################################

**GOAL:**  
Trident 20.07 introduced the possibility to import into Kubernetes a iSCSI LUN that exists in an ONTAP platform.  
A SAN Backend must already be present in order to complete this scenario. This can be achieved by following the [scenario5](../../Scenario05)

<p align="center"><img src="../Images/scenario7_2.jpg"></p>

## A. Create a volume & a LUN on the storage backend

To create these 2 objects, we will use the CURL command in order to reach ONTAP REST API:

```bash
$ curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "aggregates": [
    {
      "name": "aggr1",
      "uuid": "0dd40303-d469-4e83-86c6-2fca7838e067"
    }
  ],
  "name": "scenario7_2",
  "size": "10g",
  "style": "flexvol",
  "svm": {
    "name": "iscsi_svm",
    "uuid": "6cf8f3e4-ea3e-11ea-8644-005056b03185"
  }
}' "https://cluster1.demo.netapp.com/api/storage/volumes"

$ curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "name": "/vol/scenario7_2/lun0",
  "os_type": "linux",
  "space": {
    "size": 1073741824
  },
  "svm": {
    "name": "iscsi_svm",
    "uuid": "6cf8f3e4-ea3e-11ea-8644-005056b03185"
  }
}' "https://cluster1.demo.netapp.com/api/storage/luns"
```

A lun called **lun0** was created in the volume **scenario7_2**.  
We are now going to import this LUN into Kuberntes.

To know more about ONTAP REST API, please take a look at the following link:
https://library.netapp.com/ecmdocs/ECMLP2856304/html/index.html

## B. Import the volume

This can be achieved using the same _tridentctl import_ command used for NFS.  
Please note that:

- You need to enter the name of the volume containing the LUN & not the LUN name
- The LUN does not need to be mapped to an iGroup when importing it with Trident
- The volume hosting the LUN is going to be renamed once imported in order to follow the CSI specifications

```bash
$ tridentctl -n trident import volume san-secured scenario7_2 -f pvc_rwo_import.yaml
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
|                   NAME                   |  SIZE   |   STORAGE CLASS   | PROTOCOL |             BACKEND UUID             | STATE  | MANAGED |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+
| pvc-59d18701-4d1d-404d-9375-f403104e3e52 | 1.0 GiB | storage-class-san | block    | f75dcd7f-b69c-4910-85ed-caec90bbccc9 | online | true    |
+------------------------------------------+---------+-------------------+----------+--------------------------------------+--------+---------+

$ kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
lun-import   Bound    pvc-59d18701-4d1d-404d-9375-f403104e3e52   1Gi        RWO            storage-class-san   37s
```

Notice that the volume full name on the storage backend has changed to respect the CSI specifications:

```bash
$ kubectl get pv $(kubectl get pvc lun-import -o=jsonpath='{.spec.volumeName}') -o=jsonpath='{.spec.csi.volumeAttributes.internalName}{"\n"}'
san_chap_pvc_59d18701_4d1d_404d_9375_f403104e3e52
```

Even though the name of the original PV has changed, you can still see it if you look into its annotations.

```bash
$ kubectl describe pvc lun-import | grep importOriginalName
               trident.netapp.io/importOriginalName: scenario7_2
```

## C. Cleanup (optional)

This volume is no longer required & can be deleted from the environment.

```bash
$ kubectl delete pvc lun-import
persistentvolumeclaim "lun-import" deleted
```

## D. What's next

You can now move on to:

- [Scenario08](../../Scenario08): Consumption control  
- [Scenario09](../../Scenario09): Expanding volumes
- [Scenario10](../../Scenario10): Using Virtual Storage Pools 
- [Scenario11](../../Scenario11): StatefulSets & Storage consumption  

Or go back to the [FrontPage](https://github.com/YvosOnTheHub/LabNetApp)