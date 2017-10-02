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

set __kubectl_resources      \
  all                        \
  certificatesigningrequests \
  clusterrolebindings        \
  clusterroles               \
  clusters                   \
  componentstatuses          \
  configmaps                 \
  controllerrevisions        \
  cronjobs                   \
  daemonsets                 \
  deployments                \
  endpoints                  \
  events                     \
  horizontalpodautoscalers   \
  ingresses                  \
  jobs                       \
  limitranges                \
  namespaces                 \
  networkpolicies            \
  nodes                      \
  persistentvolumeclaims     \
  persistentvolumes          \
  poddisruptionbudgets       \
  podpreset                  \
  pods                       \
  podsecuritypolicies        \
  podtemplates               \
  replicasets                \
  replicationcontrollers     \
  resourcequotas             \
  rolebindings               \
  roles                      \
  secrets                    \
  serviceaccounts            \
  services                   \
  statefulsets               \
  storageclasses             \
  thirdpartyresources

set __k8s_timeout "--request-timeout=5s"

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
  set cmd (commandline -opc)

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

function __fish_print_resource -d 'Print a list of pods' -a resource
  set -l namespace (__fish_kubectl_get_namespace)
  set -l res ""
  if test -z "$namespace"
    kubectl get "$resource" --no-headers $__k8s_timeout | awk '{print $1}'
  else
    kubectl --namespace "$namespace" get "$resource" --no-headers $__k8s_timeout \
      | command grep -v "NAME" \
      | awk '{print $1}'
  end
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

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a get -d "Display one or many resources"
complete -c kubectl -f -n "__fish_kubectl_using_command get; and not __fish_seen_subcommand_from $__kubectl_resources" -a '(__fish_print_resource_types)' -d 'Resource'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from pods" -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from configmaps" -a '(__fish_print_resource configmaps)' -d 'Config Map'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from namespaces" -a '(__fish_print_resource namespaces)' -d 'Namespace'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from resources" -a '(__fish_print_resource resources)' -d 'Resource'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from componentstatuses" -a '(__fish_print_resource componentstatuses)' -d 'Component Statuses'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from daemonsets" -a '(__fish_print_resource daemonsets)' -d 'Daemon set'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from deployments" -a '(__fish_print_resource deployments)' -d 'Deployment'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from events" -a '(__fish_print_resource events)' -d 'Event'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from endpoints" -a '(__fish_print_resource endpoints)' -d 'Endpoint'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from horizontalpodautoscalers" -a '(__fish_print_resource horizontalpodautoscalers)' -d 'Horizontal pod auto scalers'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from ingress" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from jobs" -a '(__fish_print_resource jobs)' -d 'Job'
complete -c kubectl -f -n "__fish_kubectl_using_command get; and __fish_seen_subcommand_from cronjobs" -a '(__fish_print_resource cronjobs)' -d 'CronJob'

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a describe -d "Show details of a specific resource or group of resources"
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and not __fish_seen_subcommand_from $__kubectl_resources" -a '(__fish_print_resource_types)' -d 'Resource'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from pods" -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from pod" -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from po" -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from services" -a '(__fish_print_resource services)' -d 'Service'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from svc" -a '(__fish_print_resource services)' -d 'Service'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from configmaps" -a '(__fish_print_resource configmaps)' -d 'Config Map'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from cm" -a '(__fish_print_resource configmaps)' -d 'Config Map'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from namespaces" -a '(__fish_print_resource namespaces)' -d 'Namespace'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from ns" -a '(__fish_print_resource namespaces)' -d 'Namespace'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from resources" -a '(__fish_print_resource resources)' -d 'Resource'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from replicasets" -a '(__fish_print_resource replicasets)' -d 'ReplicaSet'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from rs" -a '(__fish_print_resource replicasets)' -d 'ReplicaSet'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from componentstatuses" -a '(__fish_print_resource componentstatuses)' -d 'Component Statuses'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from daemonsets" -a '(__fish_print_resource daemonsets)' -d 'Daemon set'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from deployments" -a '(__fish_print_resource deployments)' -d 'Deployment'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from deploy" -a '(__fish_print_resource deployments)' -d 'Deployment'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from events" -a '(__fish_print_resource events)' -d 'Event'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from ev" -a '(__fish_print_resource events)' -d 'Event'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from endpoints" -a '(__fish_print_resource endpoints)' -d 'Endpoint'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from horizontalpodautoscalers" -a '(__fish_print_resource horizontalpodautoscalers)' -d 'Horizontal pod auto scalers'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from ingress" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from ingresses" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from ing" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from jobs" -a '(__fish_print_resource jobs)' -d 'Job'
complete -c kubectl -f -n "__fish_kubectl_using_command describe; and __fish_seen_subcommand_from cronjobs" -a '(__fish_print_resource cronjobs)' -d 'Cron Job'

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a delete -d 'Delete resources by filenames, stdin, resources and names, or by resources and label selector.'
complete -c kubectl -f -n '__fish_kubectl_using_command delete; and not __fish_seen_subcommand_from $__kubectl_resources' -a '(__fish_print_resource_types)' -d 'Resource'
complete -c kubectl -f -n '__fish_kubectl_using_command delete; and __fish_seen_subcommand_from pods' -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from pod" -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from po" -a '(__fish_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from services" -a '(__fish_print_resource services)' -d 'Service'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from svc" -a '(__fish_print_resource services)' -d 'Service'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from configmaps" -a '(__fish_print_resource configmaps)' -d 'Config Map'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from cm" -a '(__fish_print_resource configmaps)' -d 'Config Map'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from namespaces" -a '(__fish_print_resource namespaces)' -d 'Namespace'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from ns" -a '(__fish_print_resource namespaces)' -d 'Namespace'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from resources" -a '(__fish_print_resource resources)' -d 'Resource'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from replicasets" -a '(__fish_print_resource replicasets)' -d 'ReplicaSet'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from rs" -a '(__fish_print_resource replicasets)' -d 'ReplicaSet'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from componentstatuses" -a '(__fish_print_resource componentstatuses)' -d 'Component Statuses'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from daemonsets" -a '(__fish_print_resource daemonsets)' -d 'Daemon set'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from deployments" -a '(__fish_print_resource deployments)' -d 'Deployment'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from deploy" -a '(__fish_print_resource deployments)' -d 'Deployment'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from events" -a '(__fish_print_resource events)' -d 'Event'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from ev" -a '(__fish_print_resource events)' -d 'Event'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from endpoints" -a '(__fish_print_resource endpoints)' -d 'Endpoint'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from horizontalpodautoscalers" -a '(__fish_print_resource horizontalpodautoscalers)' -d 'Horizontal pod auto scalers'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from ingress" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from ingresses" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from ing" -a '(__fish_print_resource ingress)' -d 'Ingress'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from jobs" -a '(__fish_print_resource jobs)' -d 'Job'
complete -c kubectl -f -n "__fish_kubectl_using_command delete; and __fish_seen_subcommand_from cronjobs" -a '(__fish_print_resource cronjobs)' -d 'Cron Job'

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a set -d "Set specific features on objects"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a create -d "Create a resource by filename or stdin"
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a replace -d "Replace a resource by filename or stdin."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a patch -d "Update field(s) of a resource using strategic merge patch."
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a edit -d "Edit a resource on the server"
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
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a label -d "Update the labels on a resource"
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
complete -c kubectl -A -f -n '__fish_seen_subcommand_from logs' -s -f -d 'Follow log output'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from logs' -a '(__fish_print_resource pods)' -d "Pod"

# exec
complete -c kubectl -f -n '__fish_kubectl_needs_command' -a exec -d 'Execute a command in a container.'
complete -c kubectl -A -f -n '__fish_seen_subcommand_from exec' -a '(__fish_print_resource pods)' -d "Pod"
