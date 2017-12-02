set __kubectl_commands \
  get                  \
  set                  \
  describe             \
  create               \
  replace              \
  patch                \
  delete               \
  edit                 \
  apply                \
  namespace            \
  logs                 \
  rolling-update       \
  scale                \
  cordon               \
  drain                \
  uncordon             \
  attach               \
  exec                 \
  port-forward         \
  proxy                \
  run                  \
  expose               \
  autoscale            \
  rollout              \
  label                \
  annotate             \
  taint                \
  config               \
  cluster-info         \
  api-versions         \
  version              \
  explain              \
  convert              \
  completion

set __kubectl_resources          \
  all                            \
  certificatesigningrequests csr \
  clusterrolebindings            \
  clusterroles                   \
  clusters                       \
  componentstatuses cs           \
  configmaps configmap cm        \
  controllerrevisions            \
  cronjobs                       \
  customresourcedefinition crd   \
  daemonsets ds                  \
  deployments deployment deploy  \
  endpoints ep                   \
  events ev                      \
  horizontalpodautoscalers hpa   \
  ingresses ingress ing          \
  jobs                           \
  limitranges limits             \
  namespaces namespace ns        \
  networkpolicies netpol         \
  nodes node no                  \
  persistentvolumeclaims pvc     \
  persistentvolumes pv           \
  poddisruptionbudgets pdb       \
  podpreset                      \
  pods pod po                    \
  podsecuritypolicies psp        \
  podtemplates                   \
  replicasets rs                 \
  replicationcontrollers rc      \
  resourcequotas quota           \
  rolebindings                   \
  roles                          \
  secrets secret                 \
  serviceaccounts sa             \
  services service svc           \
  statefulsets                   \
  storageclasses

set __k8s_timeout "--request-timeout=5s"
set __kubectl_all_namespaces_flags "--all-namespaces" "--all-namespaces=true"

function __fish_kubectl_needs_command -d 'Test if kubectl has yet to be given the subcommand'
  for i in (commandline -opc)
    if contains -- $i $__kubectl_commands
      echo "$i"
      return 1
    end
  end
  return 0
end

function __fish_kubectl_needs_resource -d 'Test if kubectl has yet to be given the subcommand resource'
  for i in (commandline -opc)
    if contains -- $i $__kubectl_resources
      return 1
    end
  end
  return 0
end


function __fish_kubectl_using_command
  set -l cmd (__fish_kubectl_needs_command)
  test -z "$cmd"
  and return 1

  contains -- $cmd $argv
  and echo "$cmd"
  and return 0

  return 1
end

function __fish_kubectl_using_resource
  set -l cmd (__fish_kubectl_needs_resource)
  test -z "$cmd"
  and return 1

  contains -- $cmd $argv
  and echo "$cmd"
  and return 0

  return 1
end

function __fish_kubectl_get_namespace -d 'Gets the namespace for the current command'
  set -l cmd (commandline -opc)
  if [ (count $cmd) -eq 0 ]
    echo ""
    return 0
  else
    set -l foundNamespace 0
    for c in $cmd
      test $foundNamespace -eq 1
      and echo "$c"
      and return 0
      if contains -- $c "--namespace" "-n"
        set foundNamespace 1
      end
    end

    return 1
  end
end

function __fish_kubectl_all_namespaces -d 'Was --all-namespaces passed'
  for i in (commandline -opc)
    if contains -- $i $__kubectl_all_namespaces_flags
      echo 1
      return 1
    end
  end
  echo 0
  return 0
end

function __fish_print_resource -d 'Print a list of resources' -a resource
  set -l all_ns (__fish_kubectl_all_namespaces)
  test $all_ns -eq 1
  and kubectl get "$resource" -o name --all-namespaces $__k8s_timeout \
    | string replace -r '(.*)/' ''
  and return

  set -l namespace (__fish_kubectl_get_namespace)
  test -z "$namespace"
  and kubectl get "$resource" -o name $__k8s_timeout \
    | string replace -r '(.*)/' ''
  and return

  kubectl --namespace "$namespace" get "$resource" -o name $__k8s_timeout \
    | string replace -r '(.*)/' ''
end

function __fish_print_resource_types
  for r in $__kubectl_resources
    echo $r
  end
end

function __fish_kubectl_get_subcommand
  set -l cmd (commandline -poc)
  set -e cmd[1]
  for i in $cmd
    if contains -- $i $argv
      echo "$i"
      return 0
    end
  end
  return 1
end

function __fish_kubectl_get_containers_for_pod -a pod
  kubectl get pods "$pod" -o 'jsonpath={.spec.containers[*].name}'
end

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a get -d "Display one or many resources"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a describe -d "Show details of a specific resource or group of resources"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a delete -d 'Delete resources by filenames, stdin, resources and names, or by resources and label selector.'
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a edit -d "Edit a resource on the server"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a label -d "Update the labels on a resource"

for subcmd in get describe delete edit label
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and not __fish_seen_subcommand_from $__kubectl_resources" -a '(__fish_print_resource_types)' -d 'Resource'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from all" -a '(__fish_print_resource all)' -d 'All'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from certificatesigningrequests" -a '(__fish_print_resource certificatesigningrequests)' -d 'Certificate Signing Requests'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from csr" -a '(__fish_print_resource csr)' -d 'Certificate Signing Requests'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from clusterrolebindings" -a '(__fish_print_resource clusterrolebindings)' -d 'Cluster Role Bindings'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from clusterroles" -a '(__fish_print_resource clusterroles)' -d 'Cluster Roles'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from clusters" -a '(__fish_print_resource clusters)' -d 'Clusters'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from componentstatuses" -a '(__fish_print_resource componentstatuses)' -d 'Component Statuses'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from cs" -a '(__fish_print_resource componentstatuses)' -d 'Component Statuses'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from configmaps" -a '(__fish_print_resource configmaps)' -d 'Config Map'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from configmap" -a '(__fish_print_resource configmaps)' -d 'Config Map'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from cm" -a '(__fish_print_resource configmaps)' -d 'Config Map'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from controllerrevisions" -a '(__fish_print_resource controllerrevisions)' -d 'Controller Revision'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from cronjobs" -a '(__fish_print_resource cronjobs)' -d 'Cron Jobs'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from customresourcedefinition" -a '(__fish_print_resource customresourcedefinition)' -d 'Custom Resource Definition'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from crd" -a '(__fish_print_resource customresourcedefinition)' -d 'Custom Resource Definition'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from daemonsets" -a '(__fish_print_resource daemonsets)' -d 'Daemon set'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ds" -a '(__fish_print_resource daemonsets)' -d 'Daemon set'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from deployments" -a '(__fish_print_resource deployments)' -d 'Deployment'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from deployment" -a '(__fish_print_resource deployments)' -d 'Deployment'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from deploy" -a '(__fish_print_resource deployments)' -d 'Deployment'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from endpoints" -a '(__fish_print_resource endpoints)' -d 'Endpoint'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ep" -a '(__fish_print_resource endpoints)' -d 'Endpoint'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from events" -a '(__fish_print_resource events)' -d 'Event'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ev" -a '(__fish_print_resource events)' -d 'Event'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from horizontalpodautoscalers" -a '(__fish_print_resource horizontalpodautoscalers)' -d 'Horizontal pod auto scalers'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from hpa" -a '(__fish_print_resource horizontalpodautoscalers)' -d 'Horizontal pod auto scalers'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ingresses" -a '(__fish_print_resource ingresses)' -d 'Ingress'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ingress" -a '(__fish_print_resource ingresses)' -d 'Ingress'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ing" -a '(__fish_print_resource ingresses)' -d 'Ingress'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from jobs" -a '(__fish_print_resource jobs)' -d 'Job'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from limitranges" -a '(__fish_print_resource limitranges)' -d 'LimitRange'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from limits" -a '(__fish_print_resource limitranges)' -d 'LimitRange'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from namespaces" -a '(__fish_print_resource namespaces)' -d 'Namespace'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from namespace" -a '(__fish_print_resource namespaces)' -d 'Namespace'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from ns" -a '(__fish_print_resource namespaces)' -d 'Namespace'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from networkpolicies" -a '(__fish_print_resource networkpolicies)' -d 'Network Policy'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from netpol" -a '(__fish_print_resource networkpolicies)' -d 'Network Policy'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from nodes" -a '(__fish_print_resource nodes)' -d 'Node'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from node" -a '(__fish_print_resource nodes)' -d 'Node'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from no" -a '(__fish_print_resource nodes)' -d 'Node'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from persistentvolumeclaims" -a '(__fish_print_resource persistentvolumeclaims)' -d 'Persistent Volume Claim'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from pvc" -a '(__fish_print_resource persistentvolumeclaims)' -d 'Persistent Volume Claim'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from persistentvolumes" -a '(__fish_print_resource persistentvolumes)' -d 'Persistent Volume'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from pv" -a '(__fish_print_resource persistentvolumes)' -d 'Persistent Volume'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from poddisruptionbudgets" -a '(__fish_print_resource poddisruptionbudgets)' -d 'Pod Disruption Budget'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from pdb" -a '(__fish_print_resource poddisruptionbudgets)' -d 'Pod Disruption Budget'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from podpreset" -a '(__fish_print_resource podpreset)' -d 'Pod Preset'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from pods" -a '(__fish_print_resource pods)' -d 'Pod'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from pod" -a '(__fish_print_resource pods)' -d 'Pod'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from po" -a '(__fish_print_resource pods)' -d 'Pod'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from podsecuritypolicies" -a '(__fish_print_resource podsecuritypolicies)' -d 'Pod Security Policy'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from psp" -a '(__fish_print_resource podsecuritypolicies)' -d 'Pod Security Policy'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from podtemplates" -a '(__fish_print_resource podtemplates)' -d 'Pod Template'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from replicasets" -a '(__fish_print_resource replicasets)' -d 'Replica Set'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from rs" -a '(__fish_print_resource replicasets)' -d 'Replica Set'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from replicationcontrollers" -a '(__fish_print_resource replicationcontrollers)' -d 'Replication Controller'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from rc" -a '(__fish_print_resource replicationcontrollers)' -d 'Replication Controller'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from resourcequotas" -a '(__fish_print_resource resourcequotas)' -d 'Resource Quota'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from quota" -a '(__fish_print_resource resourcequotas)' -d 'Resource Quota'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from rolebindings" -a '(__fish_print_resource rolebindings)' -d 'Role Binding'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from roles" -a '(__fish_print_resource roles)' -d 'Role'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from secrets" -a '(__fish_print_resource secrets)' -d 'Secret'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from secret" -a '(__fish_print_resource secrets)' -d 'Secret'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from serviceaccounts" -a '(__fish_print_resource serviceaccounts)' -d 'Service Account'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from sa" -a '(__fish_print_resource serviceaccounts)' -d 'Service Account'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from services" -a '(__fish_print_resource services)' -d 'Service'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from service" -a '(__fish_print_resource services)' -d 'Service'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from svc" -a '(__fish_print_resource services)' -d 'Service'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from statefulsets" -a '(__fish_print_resource statefulsets)' -d 'Stateful Set'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from storageclasses" -a '(__fish_print_resource storageclasses)' -d 'Storage Class'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from resources" -a '(__fish_print_resource resources)' -d 'Resource'
end

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a set -d "Set specific features on objects"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a create -d "Create a resource by filename or stdin"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a replace -d "Replace a resource by filename or stdin."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a patch -d "Update field(s) of a resource using strategic merge patch."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a apply -d "Apply a configuration to a resource by filename or stdin"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a namespace -d "SUPERSEDED: Set and view the current Kubernetes namespace"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a rolling-update -d "Perform a rolling update of the given ReplicationController."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a scale -d "Set a new size for a Deployment, ReplicaSet, Replication Controller, or Job."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a cordon -d "Mark node as unschedulable"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a drain -d "Drain node in preparation for maintenance"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a uncordon -d "Mark node as schedulable"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a attach -d "Attach to a running container."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a exec -d "Execute a command in a container."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a port-forward -d "Forward one or more local ports to a pod."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a proxy -d "Run a proxy to the Kubernetes API server"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a run -d "Run a particular image on the cluster."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a expose -d "Take a replication controller, service, deployment or pod and expose it as a new Kubernetes Service"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a autoscale -d "Auto-scale a Deployment, ReplicaSet, or ReplicationController"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a rollout -d "rollout manages a deployment"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a annotate -d "Update the annotations on a resource"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a taint -d "Update the taints on one or more nodes"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a config -d "config modifies kubeconfig files"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a cluster-info -d "Display cluster info"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a api-versions -d "Print the supported API versions on the server, in the form of \"group/version\"."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a version -d "Print the client and server version information."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a explain -d "Documentation of resources."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a convert -d "Convert config files between different API versions"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a completion -d "Output shell completion code for the given shell (bash or zsh)"

# logs
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a logs -d 'Print the logs for a container in a pod.'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from logs' -s f -l follow -d 'Follow log output'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from logs' -s l -l selector -d 'Selector (label query) to filter on'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from logs' -s p -l previous -d 'Previous instance'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from logs' -a '(__fish_print_resource pods)' -d "Pod"

# exec
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a exec -d 'Execute a command in a container.'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from exec' -a '(__fish_print_resource pods)' -d "Pod"

# version
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a version -d 'Print the client and server version information for the current context'
# -c is deprecated, so do not include it.
complete -c kubectl -A -f -n '__fish_seen_subcommand_from version' -l client -d 'Client version only (no server required)'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from version' -s o -l output -a 'yaml json' -d 'Specify output format'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from version' -l short -a 'true false' -d 'Print just the version number'
