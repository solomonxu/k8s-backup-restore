# k8s-backup-restore
A utility of  backup and restore of Kubernetes config yaml from live cluster.

## 1 Download source code from github.com source code repository
```
mkdir -p /data
cd /data
git clone https://github.com/solomonxu/k8s-backup-restore.git
```

## 2 Backup resources from K8s cluster
```
cd /data/k8s-backup-restore
./bin/k8s_backup.sh 
```

## 3 Prepare yaml file with resources of K8s cluster
```
cd /data/k8s-backup-restore/data/restore
vi 
```

## 4 Restore resources into K8s cluster
```
ls -n /data/k8s-backup-restore/data/restore
...
cd /data/k8s-backup-restore
./bin/k8s_backup.sh 
```