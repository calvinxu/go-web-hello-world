##Generate tock for the dashboard
1. Creating a Service Account
#cat dashboard-adminuser.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
#kubectl apply -f dashboard-adminuser.yaml 
2. Creating a ClusterRoleBinding
#cat dashboard-rolebinding.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
#kubectl apply -f dashboard-rolebinding.yaml 
3. Getting a Bearer Token
#kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
Name:         admin-user-token-9s5pp
Namespace:    kubernetes-dashboard
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin-user
              kubernetes.io/service-account.uid: 6c70ff89-f7dc-403b-ba3d-ccdea1822a3b

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1099 bytes
namespace:  20 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IndZS2NMUGtUQWZYYVlCeGYxV2dpaVFVNUJIbHgtLXlnOEJGUzc0MWJob0UifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLTlzNXBwIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI2YzcwZmY4OS1mN2RjLTQwM2ItYmEzZC1jY2RlYTE4MjJhM2IiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.s5JLRSHPjoQH8-t-6WXa0pZhC6Cf7PB0BR0zOwgCQnto5goGpNtsxTIgqo5A94x_-pwgb4xpOB6TO4XDU0tsnI3iNbsgAFY7dxFt6bNqCSDWWzyH0Pf25smdd9QWwRJ-7Tn4wtOHUu-LbgizqX-gpwI_dJi1rRklyP_VwrVDfr0cokaZAzb4vtzgV1AkZZn9T4uhlkjUBDR29rNOdV7RyhrAS7LLjrHb5buJCTQAfLFnfLYhs_NjGHdcU2_ml6nAmw_NEzUnaW2FXATnFEdEVVAaZzihLOReTIBSm5ec4IzEyXV4UMtDnsalXu09quWrBFz84pbvVvsIJM5bjJ-u9w
 
The above token can be used to access the dashboard through the selection of Token access

