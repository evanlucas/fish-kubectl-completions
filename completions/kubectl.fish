#
set -q FISH_KUBECTL_COMPLETION_TIMEOUT; or set FISH_KUBECTL_COMPLETION_TIMEOUT 5s
set -q FISH_KUBECTL_COMPLETION_COMPLETE_CRDS; or set FISH_KUBECTL_COMPLETION_COMPLETE_CRDS 1
set __fish_kubectl_timeout "--request-timeout=$FISH_KUBECTL_COMPLETION_TIMEOUT"
set __fish_kubectl_all_namespaces_flags "--all-namespaces" "--all-namespaces=true"
set __fish_kubectl_subresource_commands get describe delete edit label explain
set __fish_kubectl_commands alpha \
  annotate \
  api-resources \
  api-versions \
  apply \
  attach \
  auth \
  autoscale \
  certificate \
  cluster-info \
  completion \
  config \
  cordon \
  cp \
  create \
  debug \
  delete \
  describe \
  diff \
  drain \
  edit \
  exec \
  explain \
  expose \
  get \
  kustomize \
  label \
  logs \
  options \
  patch \
  plugin \
  port-forward \
  proxy \
  replace \
  rollout \
  run \
  scale \
  set \
  taint \
  top \
  uncordon \
  version \
  wait

function __fish_kubectl
	set -l context_args

	if set -l context_flags (__fish_kubectl_get_context_flags | string split " ")
		for c in $context_flags
			set context_args $context_args $c
		end
	end

  command kubectl $__fish_kubectl_timeout $context_args $argv
end

function __fish_kubectl_get_commands
  echo alpha\t'Commands for features in alpha'
  echo annotate\t'Update the annotations on a resource'
  echo api-resources\t'Print the supported API resources on the server'
  echo api-versions\t'Print the supported API versions on the server, in the form of "group/version"'
  echo apply\t'Apply a configuration to a resource by filename or stdin'
  echo attach\t'Attach to a running container'
  echo auth\t'Inspect authorization'
  echo autoscale\t'Auto-scale a Deployment, ReplicaSet, or ReplicationController'
  echo certificate\t'Modify certificate resources.'
  echo cluster-info\t'Display cluster info'
  echo completion\t'Output shell completion code for the specified shell (bash or zsh)'
  echo config\t'Modify kubeconfig files'
  echo cordon\t'Mark node as unschedulable'
  echo cp\t'Copy files and directories to and from containers.'
  echo create\t'Create a resource from a file or from stdin.'
  echo debug\t'Create debugging sessions for troubleshooting workloads and nodes'
  echo delete\t'Delete resources by filenames, stdin, resources and names, or by resources and label selector'
  echo describe\t'Show details of a specific resource or group of resources'
  echo diff\t'Diff live version against would-be applied version'
  echo drain\t'Drain node in preparation for maintenance'
  echo edit\t'Edit a resource on the server'
  echo exec\t'Execute a command in a container'
  echo explain\t'Documentation of resources'
  echo expose\t'Take a replication controller, service, deployment or pod and expose it as a new Kubernetes Service'
  echo get\t'Display one or many resources'
  echo kustomize\t'Build a kustomization target from a directory or a remote url.'
  echo label\t'Update the labels on a resource'
  echo logs\t'Print the logs for a container in a pod'
  echo options\t'Print the list of flags inherited by all commands'
  echo patch\t'Update field(s) of a resource'
  echo plugin\t'Provides utilities for interacting with plugins.'
  echo port-forward\t'Forward one or more local ports to a pod'
  echo proxy\t'Run a proxy to the Kubernetes API server'
  echo replace\t'Replace a resource by filename or stdin'
  echo rollout\t'Manage the rollout of a resource'
  echo run\t'Run a particular image on the cluster'
  echo scale\t'Set a new size for a Deployment, ReplicaSet or Replication Controller'
  echo set\t'Set specific features on objects'
  echo taint\t'Update the taints on one or more nodes'
  echo top\t'Display Resource (CPU/Memory/Storage) usage.'
  echo uncordon\t'Mark node as schedulable'
  echo version\t'Print the client and server version information'
  echo wait\t'Experimental: Wait for a specific condition on one or many resources.'
end

set __fish_kubectl_resources        \
  all                               \
  certificatesigningrequests csr    \
  clusterrolebindings               \
  clusterroles                      \
  clusters                          \
  componentstatuses cs              \
  configmaps configmap cm           \
  controllerrevisions               \
  cronjobs cj                       \
  customresourcedefinition crd crds \
  daemonsets ds                     \
  deployments deployment deploy     \
  endpoints ep                      \
  events ev                         \
  horizontalpodautoscalers hpa      \
  ingresses ingress ing             \
  jobs job                          \
  limitranges limits                \
  namespaces namespace ns           \
  networkpolicies netpol            \
  nodes node no                     \
  persistentvolumeclaims pvc        \
  persistentvolumes pv              \
  poddisruptionbudgets pdb          \
  podpreset                         \
  pods pod po                       \
  podsecuritypolicies psp           \
  podtemplates                      \
  replicasets rs                    \
  replicationcontrollers rc         \
  resourcequotas quota              \
  rolebindings                      \
  roles                             \
  secrets secret                    \
  serviceaccounts sa                \
  services service svc              \
  statefulsets sts                  \
  storageclass storageclasses sc

set __fish_kubectl_cached_crds ""
set __fish_kubectl_last_crd_fetch ""

function __fish_kubectl_actually_get_crds
  set __fish_kubectl_cached_crds (__fish_kubectl get crd -o jsonpath='{range .items[*]}{.spec.names.plural}{"\n"}{.spec.names.singular}{"\n"}{range .spec.names.shortNames[]}{@}{"\n"}{end}{end}' 2>/dev/null)
  set __fish_kubectl_last_crd_fetch (__fish_kubectl_get_current_time)
	for i in $__fish_kubectl_cached_crds
		echo $i
	end
end

function __fish_kubectl_get_current_time
  date +'%s'
end

function __fish_kubectl_get_crds
  if test -z "$__fish_kubectl_last_crd_fetch"; or test -z "$__fish_kubectl_cached_crds"
    __fish_kubectl_actually_get_crds
    return 0
  end

  set -l ct (__fish_kubectl_get_current_time)
	set -l duration (math $ct-$__fish_kubectl_last_crd_fetch)
	# Only fetch crds if we have not fetched them within the past 30 seconds.
  if test "$duration" -gt 30
    __fish_kubectl_actually_get_crds
    return 0
  end

  for i in $__fish_kubectl_cached_crds
		echo $i
	end
end

function __fish_kubectl_seen_subcommand_from_regex
  set -l cmd (commandline -poc)
  set -e cmd[1]
  for i in $cmd
    for r in $argv
      if string match -r -- $r $i
        return 0
      end
    end
  end
  return 1
end

function __fish_kubectl_needs_command -d 'Test if kubectl has yet to be given the subcommand'
  for i in (commandline -opc)
    if contains -- $i $__fish_kubectl_commands
      echo "$i"
      return 1
    end
  end
  return 0
end

function __fish_kubectl_needs_resource -d 'Test if kubectl has yet to be given the subcommand resource'
  set -l resources (__fish_kubectl_print_resource_types)
  for i in (commandline -opc)
    if contains -- $i $resources
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

function __fish_kubectl_has_partial_resource_match
  set -l last (commandline -opt)
  if not set -l matches (string match -- "(.*)/" $last)
    return
  end

  if string match -q -- "(.*)/" $last
    return 0
  end

  return 1
end

function __fish_kubectl_print_matching_resources
  set -l last (commandline -opt)
  if not set -l matches (string match -r -- "(.*)/" $last)
    return
  end
  set -l prefix $matches[2]
  set -l resources (__fish_kubectl_print_resource "$prefix")
  for i in $resources
    echo "$prefix/$i"
  end
end

function __fish_kubectl_get_context_flags
	set -l cmd (commandline -opc)
	if [ (count $cmd) -eq 0 ]
		return 1
	end

	set -l foundContext 0

	for c in $cmd
		test $foundContext -eq 1
		set -l out "--context" "$c"
		and echo $out
		and return 0

		if string match -q -r -- "--context=" "$c"
			set -l out (string split -- "=" "$c" | string join " ")
			and echo $out
			and return 0
		else if contains -- "$c" "--context"
			set foundContext 1
		end
	end

	return 1
end

function __fish_kubectl_get_ns_flags
  set -l cmd (commandline -opc)
  if [ (count $cmd) -eq 0 ]
    return 1
  end

  set -l foundNamespace 0

  for c in $cmd
    test $foundNamespace -eq 1
    set -l out "--namespace" "$c"
    and echo $out
    and return 0

    if contains -- $c $__kubectl_all_namespaces_flags
      echo "--all-namespaces"
      return 0
    end

    if contains -- $c "--namespace" "-n"
      set foundNamespace 1
    end
  end

  return 1
end

function __fish_kubectl_print_resource_types
  for r in $__fish_kubectl_resources
    echo $r
  end

	if test $FISH_KUBECTL_COMPLETION_COMPLETE_CRDS -eq 1
		set -l crds (__fish_kubectl_get_crds)

		for r in $crds
			echo $r
		end
	end
end

function __fish_kubectl_print_current_resources -d 'Prints current resources'
  set -l found 0
  # There is probably a better way to do this...
  # found === 1 means that we have not yet found the crd type
  # found === 2 means that we have not yet found the crd name, but have found the type
  set -l current_resource
  set -l crd_types (__fish_kubectl_get_crds)
  for i in (commandline -opc)
    if test $found -eq 0
      if contains -- $i $__fish_kubectl_subresource_commands
        set found 1
      end
    end

    if test $found -eq 1
      if contains -- $i $crd_types
        set -l out (__fish_kubectl_print_resource $i)
        for item in $out
          echo "$item"
        end
        return 0
      end
    end
  end
end

function __fish_kubectl_print_resource -d 'Print a list of resources' -a resource
  set -l args
  if set -l ns_flags (__fish_kubectl_get_ns_flags | string split " ")
    for ns in $ns_flags
      set args $args $ns
    end
  end

  set args $args get "$resource"
  __fish_kubectl $args --no-headers 2>/dev/null | awk '{print $1}' | string replace -r '(.*)/' ''
end

function __fish_kubectl_get_config -a type
  set -l template "{{ range .$type }}"'{{ .name }}{{"\n"}}{{ end }}'
  __fish_kubectl config view -o template --template="$template"
end

function __fish_kubectl_get_rollout_resources
  set -l args
  if set -l ns_flags (__fish_kubectl_get_ns_flags | string split " ")
    for ns in $ns_flags
      set args $args $ns
    end
  end

  set -l template '{range .items[*]}{.metadata.name}{"\n"}{end}'

  set -l deploys (__fish_kubectl $args get deploy -o jsonpath="$template" 2>/dev/null)
  set -l daemonsets (__fish_kubectl $args get ds -o jsonpath="$template" 2>/dev/null)
  set -l sts (__fish_kubectl $args get sts -o jsonpath="$template" 2>/dev/null)

  for i in $deploys
    echo "deploy/$i"
    echo "deployment/$i"
    echo "deployments/$i"
  end

  for i in $daemonsets
    echo "daemonset/$i"
    echo "daemonsets/$i"
    echo "ds/$i"
  end

  for i in $sts
    echo "statefulset/$i"
    echo "statefulsets/$i"
    echo "sts/$i"
  end
end

complete -c kubectl -f -n '__fish_kubectl_needs_command' -a '(__fish_kubectl_get_commands)'

for subcmd in $__fish_kubectl_subresource_commands
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and not __fish_seen_subcommand_from (__fish_kubectl_print_resource_types)" -a '(__fish_kubectl_print_resource_types)' -d 'Resource'
  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_kubectl_has_partial_resource_match" -a '(__fish_kubectl_print_matching_resources)' -d 'Resource'
  for resource in $__fish_kubectl_resources
    complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from $resource" -a "(__fish_kubectl_print_resource $resource)" -d "$resource"
  end

	if test $FISH_KUBECTL_COMPLETION_COMPLETE_CRDS -eq 1
		complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from (__fish_kubectl_get_crds)" -a '(__fish_kubectl_print_current_resources)' -d 'CRD'
	end
end

complete -c kubectl -f -n "__fish_seen_subcommand_from log logs exec port-forward" -a '(__fish_kubectl_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_seen_subcommand_from top; and __fish_seen_subcommand_from po pod pods" -a '(__fish_kubectl_print_resource pods)' -d 'Pod'
complete -c kubectl -f -n "__fish_seen_subcommand_from top; and __fish_seen_subcommand_from no node nodes" -a '(__fish_kubectl_print_resource nodes)' -d 'Node'

for subcmd in cordon uncordon drain taint
  complete -c kubectl -f -n "__fish_seen_subcommand_from $subcmd" -a '(__fish_kubectl_print_resource nodes)' -d 'Node'
end

set -l __fish_kubectl_config_complete_contexts \
  delete-context \
  get-contexts \
  rename-contexts \
  set-context \
  use-context

set -l __fish_kubectl_config_complete_clusters \
  delete-cluster \
  get-clusters \
  set-cluster

complete -c kubectl -f -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from $__fish_kubectl_config_complete_contexts" -a '(__fish_kubectl_get_config contexts)' -d 'Context'
complete -c kubectl -f -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from $__fish_kubectl_config_complete_clusters" -a '(__fish_kubectl_get_config clusters)' -d 'Cluster'
complete -c kubectl -f -n "__fish_seen_subcommand_from rollout; and __fish_seen_subcommand_from (__fish_kubectl_get_rollout_commands_without_descriptions)" -a '(__fish_kubectl_get_rollout_resources)'
complete -c kubectl -f -r -l as -d 'Username to impersonate for the operation'
complete -c kubectl -f -r -l as-group -d 'Group to impersonate for the operation, this flag can be repeated to specify multiple groups.'
complete -c kubectl -r -l cache-dir -d 'Default cache directory'
complete -c kubectl -r -l certificate-authority -d 'Path to a cert file for the certificate authority'
complete -c kubectl -r -l client-certificate -d 'Path to a client certificate file for TLS'
complete -c kubectl -r -l client-key -d 'Path to a client key file for TLS'
complete -c kubectl -f -r -l cluster -d 'The name of the kubeconfig cluster to use' -a '(__fish_kubectl_get_config clusters)'
complete -c kubectl -f -r -l context -d 'The name of the kubeconfig context to use' -a '(__fish_kubectl_get_config contexts)'
complete -c kubectl -f -l insecure-skip-tls-verify -d 'If true, the server\'s certificate will not be checked for validity. This will make your HTTPS connections insecure'
complete -c kubectl -r -l kubeconfig -d 'Path to the kubeconfig file to use for CLI requests.'
complete -c kubectl -f -l match-server-version -d 'Require server version to match client version'
complete -c kubectl -f -r -s n -l namespace -d 'If present, the namespace scope for this CLI request' -a '(__fish_kubectl_print_resource namespace)'
complete -c kubectl -f -r -l password -d 'Password for basic authentication to the API server'
complete -c kubectl -f -r -l profile -d 'Name of profile to capture. One of (none|cpu|heap|goroutine|threadcreate|block|mutex)'
complete -c kubectl -f -r -l profile-output -d 'Name of the file to write the profile to'
complete -c kubectl -f -r -l request-timeout -d 'The length of time to wait before giving up on a single server request. Non-zero values should contain a corresponding time unit (e.g. 1s, 2m, 3h). A value of zero means don\'t timeout requests.'
complete -c kubectl -f -r -s s -l server -d 'The address and port of the Kubernetes API server'
complete -c kubectl -f -r -l tls-server-name -d 'Server name to use for server certificate validation. If it is not provided, the hostname used to contact the server is used'
complete -c kubectl -f -r -l token -d 'Bearer token for authentication to the API server'
complete -c kubectl -f -r -l user -d 'The name of the kubeconfig user to use' -a '(__fish_kubectl_get_config users)'
complete -c kubectl -f -r -l username -d 'Username for basic authentication to the API server'
complete -c kubectl -f -l warnings-as-errors -d 'Treat warnings received from the server as errors and exit with a non-zero exit code'

# Completions for the "kubectl alpha" command
function __fish_kubectl_get_alpha_commands
  echo debug\t'Create debugging sessions for troubleshooting workloads and nodes'
end

function __fish_kubectl_get_alpha_commands_without_descriptions
  __fish_kubectl_get_alpha_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command alpha; and not __fish_seen_subcommand_from (__fish_kubectl_get_alpha_commands_without_descriptions)" -a '(__fish_kubectl_get_alpha_commands)'

# Completions for the "kubectl alpha debug" command
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -l arguments-only -d 'If specified, everything after -- will be passed to the new container as Args instead of Command.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -l attach -d 'If true, wait for the container to start running, and then attach as if \'kubectl attach ...\' were called.  Default false, unless \'-i/--stdin\' is set, in which case the default is true.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -s c -l container -d 'Container name to use for debug container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -l copy-to -d 'Create a copy of the target Pod with this name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -l env -d 'Environment variables to set in the container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -l image -d 'Container image to use for debug container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -l image-pull-policy -d 'The image pull policy for the container. If left empty, this value will not be specified by the client and defaulted by the server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -l quiet -d 'If true, suppress informational messages.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -l replace -d 'When used with \'--copy-to\', delete the original Pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -l same-node -d 'When used with \'--copy-to\', schedule the copy of target Pod on the same node.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -l set-image -d 'When used with \'--copy-to\', a list of name=image pairs for changing container images, similar to how \'kubectl set image\' works.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -l share-processes -d 'When used with \'--copy-to\', enable process namespace sharing in the copy.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -s i -l stdin -d 'Keep stdin open on the container(s) in the pod, even if nothing is attached.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -r -l target -d 'When using an ephemeral container, target processes in this container name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from alpha debug' -s t -l tty -d 'Allocate a TTY for the debugging container.'

# Completions for the "kubectl annotate" command
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -l field-selector -d 'Selector (field query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. --field-selector key1=value1,key2=value2). The server only supports a limited number of field queries per type.'
complete -c kubectl -n '__fish_seen_subcommand_from annotate' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to update the annotation'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -l list -d 'If true, display the annotations for a given resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -l local -d 'If true, annotation will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -l overwrite -d 'If true, allow annotations to be overwritten, otherwise reject annotation updates that overwrite existing annotations.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -l resource-version -d 'If non-empty, the annotation update will only succeed if this is the current resource-version for the object. Only valid when specifying a single resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from annotate' -r -s l -l selector -d 'Selector (label query) to filter on, not including uninitialized ones, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2).'
complete -c kubectl -n '__fish_seen_subcommand_from annotate' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl api-resources" command
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -r -l api-group -d 'Limit to resources in the specified API group.'
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -l cached -d 'Use the cached list of resources if available.'
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -l namespaced -d 'If false, non-namespaced resources will be returned, otherwise returning namespaced resources by default.'
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -l no-headers -d 'When using the default or custom-column output format, don\'t print headers (default print headers).'
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -r -s o -l output -d 'Output format. One of: wide|name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -r -l sort-by -d 'If non-empty, sort list of resources using specified field. The field can be either \'name\' or \'kind\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from api-resources' -r -l verbs -d 'Limit to resources that support the specified verbs.'

# Completions for the "kubectl apply" command
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l all -d 'Select all resources in the namespace of the specified resource types.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -l cascade -d 'Must be "background", "orphan", or "foreground". Selects the deletion cascading strategy for the dependents (e.g. Pods created by a ReplicationController). Defaults to background.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from apply' -r -s f -l filename -d 'that contains the configuration to apply'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l force -d 'If true, immediately remove resources from API and bypass graceful deletion. Note that immediate deletion of some resources may result in inconsistency or data loss and requires confirmation.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l force-conflicts -d 'If true, server-side apply will force the changes against conflicts.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -l grace-period -d 'Period of time in seconds given to the resource to terminate gracefully. Ignored if negative. Set to 1 for immediate shutdown. Can only be set to 0 when --force is true (force deletion).'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -s k -l kustomize -d 'Process a kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l openapi-patch -d 'If true, use openapi to calculate diff when the openapi presents and the resource can be found in the openapi spec. Otherwise, fall back to use baked-in types.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l overwrite -d 'Automatically resolve conflicts between the modified and live configuration by using values from the modified configuration'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l prune -d 'Automatically delete resource objects, including the uninitialized ones, that do not appear in the configs and are created by either apply or create --save-config. Should be used with either -l or --all.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -l prune-whitelist -d 'Overwrite the default whitelist with <group/version/kind> for --prune'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l server-side -d 'If true, apply runs in the server instead of the client.'
complete -c kubectl -n '__fish_seen_subcommand_from apply' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -r -l timeout -d 'The length of time to wait before giving up on a delete, zero means determine a timeout from the size of the object'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply' -l wait -d 'If true, wait for resources to be gone before returning. This waits for finalizers.'
function __fish_kubectl_get_apply_commands
  echo edit-last-applied\t'Edit latest last-applied-configuration annotations of a resource/object'
  echo set-last-applied\t'Set the last-applied-configuration annotation on a live object to match the contents of a file.'
  echo view-last-applied\t'View latest last-applied-configuration annotations of a resource/object'
end

function __fish_kubectl_get_apply_commands_without_descriptions
  __fish_kubectl_get_apply_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command apply; and not __fish_seen_subcommand_from (__fish_kubectl_get_apply_commands_without_descriptions)" -a '(__fish_kubectl_get_apply_commands)'

# Completions for the "kubectl apply edit-last-applied" command
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from apply edit-last-applied' -r -s f -l filename -d 'Filename, directory, or URL to files to use to edit the resource'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from apply edit-last-applied' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply edit-last-applied' -l windows-line-endings -d 'Defaults to the line ending native to your platform.'

# Completions for the "kubectl apply set-last-applied" command
complete -c kubectl -f -n '__fish_seen_subcommand_from apply set-last-applied' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply set-last-applied' -l create-annotation -d 'Will create \'last-applied-configuration\' annotations if current objects doesn\'t have one'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply set-last-applied' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -n '__fish_seen_subcommand_from apply set-last-applied' -r -s f -l filename -d 'Filename, directory, or URL to files that contains the last-applied-configuration annotations'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply set-last-applied' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -n '__fish_seen_subcommand_from apply set-last-applied' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl apply view-last-applied" command
complete -c kubectl -f -n '__fish_seen_subcommand_from apply view-last-applied' -l all -d 'Select all resources in the namespace of the specified resource types'
complete -c kubectl -n '__fish_seen_subcommand_from apply view-last-applied' -r -s f -l filename -d 'Filename, directory, or URL to files that contains the last-applied-configuration annotations'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply view-last-applied' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply view-last-applied' -r -s o -l output -d 'Output format. Must be one of yaml|json'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply view-last-applied' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from apply view-last-applied' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'

# Completions for the "kubectl attach" command
complete -c kubectl -f -n '__fish_seen_subcommand_from attach' -r -s c -l container -d 'Container name. If omitted, the first container in the pod will be chosen'
complete -c kubectl -f -n '__fish_seen_subcommand_from attach' -r -l pod-running-timeout -d 'The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running'
complete -c kubectl -f -n '__fish_seen_subcommand_from attach' -s i -l stdin -d 'Pass stdin to the container'
complete -c kubectl -f -n '__fish_seen_subcommand_from attach' -s t -l tty -d 'Stdin is a TTY'

# Completions for the "kubectl auth" command
function __fish_kubectl_get_auth_commands
  echo can-i\t'Check whether an action is allowed'
  echo reconcile\t'Reconciles rules for RBAC Role, RoleBinding, ClusterRole, and ClusterRole binding objects'
end

function __fish_kubectl_get_auth_commands_without_descriptions
  __fish_kubectl_get_auth_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command auth; and not __fish_seen_subcommand_from (__fish_kubectl_get_auth_commands_without_descriptions)" -a '(__fish_kubectl_get_auth_commands)'

# Completions for the "kubectl auth can-i" command
complete -c kubectl -f -n '__fish_seen_subcommand_from auth can-i' -s A -l all-namespaces -d 'If true, check the specified action in all namespaces.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth can-i' -l list -d 'If true, prints all allowed actions.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth can-i' -l no-headers -d 'If true, prints allowed actions without headers'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth can-i' -s q -l quiet -d 'If true, suppress output and just return the exit code.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth can-i' -r -l subresource -d 'SubResource such as pod/log or deployment/scale'

# Completions for the "kubectl auth reconcile" command
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -n '__fish_seen_subcommand_from auth reconcile' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to reconcile.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -l remove-extra-permissions -d 'If true, removes extra permissions added to roles'
complete -c kubectl -f -n '__fish_seen_subcommand_from auth reconcile' -l remove-extra-subjects -d 'If true, removes extra subjects added to rolebindings'
complete -c kubectl -n '__fish_seen_subcommand_from auth reconcile' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl autoscale" command
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -l cpu-percent -d 'The target average CPU utilization (represented as a percent of requested CPU) over all the pods. If it\'s not specified or negative, a default autoscaling policy will be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from autoscale' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to autoscale.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -l max -d 'The upper limit for the number of pods that can be set by the autoscaler. Required.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -l min -d 'The lower limit for the number of pods that can be set by the autoscaler. If it\'s not specified or negative, the server will apply a default value.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -l name -d 'The name for the newly created object. If not specified, the name of the input resource will be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from autoscale' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from autoscale' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl certificate" command
function __fish_kubectl_get_certificate_commands
  echo approve\t'Approve a certificate signing request'
  echo deny\t'Deny a certificate signing request'
end

function __fish_kubectl_get_certificate_commands_without_descriptions
  __fish_kubectl_get_certificate_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command certificate; and not __fish_seen_subcommand_from (__fish_kubectl_get_certificate_commands_without_descriptions)" -a '(__fish_kubectl_get_certificate_commands)'

# Completions for the "kubectl certificate approve" command
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate approve' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -n '__fish_seen_subcommand_from certificate approve' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to update'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate approve' -l force -d 'Update the CSR even if it is already approved.'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate approve' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate approve' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate approve' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from certificate approve' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl certificate deny" command
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate deny' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -n '__fish_seen_subcommand_from certificate deny' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to update'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate deny' -l force -d 'Update the CSR even if it is already denied.'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate deny' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate deny' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from certificate deny' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from certificate deny' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl cluster-info" command
function __fish_kubectl_get_cluster_info_commands
  echo dump\t'Dump lots of relevant info for debugging and diagnosis'
end

function __fish_kubectl_get_cluster_info_commands_without_descriptions
  __fish_kubectl_get_cluster_info_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command cluster-info; and not __fish_seen_subcommand_from (__fish_kubectl_get_cluster_info_commands_without_descriptions)" -a '(__fish_kubectl_get_cluster_info_commands)'

# Completions for the "kubectl cluster-info dump" command
complete -c kubectl -f -n '__fish_seen_subcommand_from cluster-info dump' -s A -l all-namespaces -d 'If true, dump all namespaces.  If true, --namespaces is ignored.'
complete -c kubectl -f -n '__fish_seen_subcommand_from cluster-info dump' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from cluster-info dump' -r -l namespaces -d 'A comma separated list of namespaces to dump.'
complete -c kubectl -f -n '__fish_seen_subcommand_from cluster-info dump' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from cluster-info dump' -r -l output-directory -d 'Where to output the files.  If empty or \'-\' uses stdout, otherwise creates a directory hierarchy in that directory'
complete -c kubectl -f -n '__fish_seen_subcommand_from cluster-info dump' -r -l pod-running-timeout -d 'The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running'
complete -c kubectl -n '__fish_seen_subcommand_from cluster-info dump' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl config" command
function __fish_kubectl_get_config_commands
  echo current-context\t'Displays the current-context'
  echo delete-cluster\t'Delete the specified cluster from the kubeconfig'
  echo delete-context\t'Delete the specified context from the kubeconfig'
  echo delete-user\t'Delete the specified user from the kubeconfig'
  echo get-clusters\t'Display clusters defined in the kubeconfig'
  echo get-contexts\t'Describe one or many contexts'
  echo get-users\t'Display users defined in the kubeconfig'
  echo rename-context\t'Renames a context from the kubeconfig file.'
  echo set\t'Sets an individual value in a kubeconfig file'
  echo set-cluster\t'Sets a cluster entry in kubeconfig'
  echo set-context\t'Sets a context entry in kubeconfig'
  echo set-credentials\t'Sets a user entry in kubeconfig'
  echo unset\t'Unsets an individual value in a kubeconfig file'
  echo use-context\t'Sets the current-context in a kubeconfig file'
  echo use\t'Sets the current-context in a kubeconfig file'
  echo view\t'Display merged kubeconfig settings or a specified kubeconfig file'
end

function __fish_kubectl_get_config_commands_without_descriptions
  __fish_kubectl_get_config_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command config; and not __fish_seen_subcommand_from (__fish_kubectl_get_config_commands_without_descriptions)" -a '(__fish_kubectl_get_config_commands)'

# Completions for the "kubectl config get-contexts" command
complete -c kubectl -f -n '__fish_seen_subcommand_from config get-contexts' -l no-headers -d 'When using the default or custom-column output format, don\'t print headers (default print headers).'
complete -c kubectl -f -n '__fish_seen_subcommand_from config get-contexts' -r -s o -l output -d 'Output format. One of: name'

# Completions for the "kubectl config set" command
complete -c kubectl -f -n '__fish_seen_subcommand_from config set' -r -l set-raw-bytes -d 'When writing a []byte PROPERTY_VALUE, write the given string directly without base64 decoding.'

# Completions for the "kubectl config set-cluster" command
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-cluster' -r -l embed-certs -d 'embed-certs for the cluster entry in kubeconfig'

# Completions for the "kubectl config set-context" command
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-context' -l current -d 'Modify the current context'

# Completions for the "kubectl config set-credentials" command
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l auth-provider -d 'Auth provider for the user entry in kubeconfig'
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l auth-provider-arg -d '\'key=value\' arguments for the auth provider'
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l embed-certs -d 'Embed client cert/key for the user entry in kubeconfig'
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l exec-api-version -d 'API version of the exec credential plugin for the user entry in kubeconfig'
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l exec-arg -d 'New arguments for the exec credential plugin command for the user entry in kubeconfig'
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l exec-command -d 'Command for the exec credential plugin for the user entry in kubeconfig'
complete -c kubectl -f -n '__fish_seen_subcommand_from config set-credentials' -r -l exec-env -d '\'key=value\' environment values for the exec credential plugin'

# Completions for the "kubectl config view" command
complete -c kubectl -f -n '__fish_seen_subcommand_from config view' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from config view' -l flatten -d 'Flatten the resulting kubeconfig file into self-contained output (useful for creating portable kubeconfig files)'
complete -c kubectl -f -n '__fish_seen_subcommand_from config view' -r -l merge -d 'Merge the full hierarchy of kubeconfig files'
complete -c kubectl -f -n '__fish_seen_subcommand_from config view' -l minify -d 'Remove all information not used by current-context from the output'
complete -c kubectl -f -n '__fish_seen_subcommand_from config view' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from config view' -l raw -d 'Display raw byte data'
complete -c kubectl -n '__fish_seen_subcommand_from config view' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl cordon" command
complete -c kubectl -f -n '__fish_seen_subcommand_from cordon' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from cordon' -r -s l -l selector -d 'Selector (label query) to filter on'

# Completions for the "kubectl cp" command
complete -c kubectl -f -n '__fish_seen_subcommand_from cp' -r -s c -l container -d 'Container name. If omitted, the first container in the pod will be chosen'
complete -c kubectl -f -n '__fish_seen_subcommand_from cp' -l no-preserve -d 'The copied file/directory\'s ownership and permissions will not be preserved in the container'

# Completions for the "kubectl create" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -l edit -d 'Edit the API resource before creating'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from create' -r -s f -l filename -d 'Filename, directory, or URL to files to use to create the resource'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -r -l raw -d 'Raw URI to POST to the server.  Uses the transport specified by the kubeconfig file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -n '__fish_seen_subcommand_from create' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create' -l windows-line-endings -d 'Only relevant if --edit=true. Defaults to the line ending native to your platform.'
function __fish_kubectl_get_create_commands
  echo clusterrole\t'Create a ClusterRole.'
  echo clusterrolebinding\t'Create a ClusterRoleBinding for a particular ClusterRole'
  echo configmap\t'Create a configmap from a local file, directory or literal value'
  echo cm\t'Create a configmap from a local file, directory or literal value'
  echo cronjob\t'Create a cronjob with the specified name.'
  echo cj\t'Create a cronjob with the specified name.'
  echo deployment\t'Create a deployment with the specified name.'
  echo deploy\t'Create a deployment with the specified name.'
  echo ingress\t'Create an ingress with the specified name.'
  echo ing\t'Create an ingress with the specified name.'
  echo job\t'Create a job with the specified name.'
  echo namespace\t'Create a namespace with the specified name'
  echo ns\t'Create a namespace with the specified name'
  echo poddisruptionbudget\t'Create a pod disruption budget with the specified name.'
  echo pdb\t'Create a pod disruption budget with the specified name.'
  echo priorityclass\t'Create a priorityclass with the specified name.'
  echo pc\t'Create a priorityclass with the specified name.'
  echo quota\t'Create a quota with the specified name.'
  echo resourcequota\t'Create a quota with the specified name.'
  echo role\t'Create a role with single rule.'
  echo rolebinding\t'Create a RoleBinding for a particular Role or ClusterRole'
  echo secret\t'Create a secret using specified subcommand'
  echo service\t'Create a service using specified subcommand.'
  echo svc\t'Create a service using specified subcommand.'
  echo serviceaccount\t'Create a service account with the specified name'
  echo sa\t'Create a service account with the specified name'
end

function __fish_kubectl_get_create_commands_without_descriptions
  __fish_kubectl_get_create_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command create; and not __fish_seen_subcommand_from (__fish_kubectl_get_create_commands_without_descriptions)" -a '(__fish_kubectl_get_create_commands)'

# Completions for the "kubectl create clusterrole" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l aggregation-rule -d 'An aggregation label selector for combining ClusterRoles.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l non-resource-url -d 'A partial url that user should have access to.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l resource -d 'Resource that the rule applies to'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l resource-name -d 'Resource in the white list that the rule applies to, repeat this flag for multiple items'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create clusterrole' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrole' -r -l verb -d 'Verb that applies to the resources contained in the rule'

# Completions for the "kubectl create clusterrolebinding" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -r -l clusterrole -d 'ClusterRole this ClusterRoleBinding should reference'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -r -l group -d 'Groups to bind to the clusterrole'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -r -l serviceaccount -d 'Service accounts to bind to the clusterrole, in the format <namespace>:<name>'
complete -c kubectl -n '__fish_seen_subcommand_from create clusterrolebinding' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create clusterrolebinding' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create configmap" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -l append-hash -d 'Append a hash of the configmap to its name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -l append-hash -d 'Append a hash of the configmap to its name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -r -l from-env-file -d 'Specify the path to a file to read lines of key=val pairs to create a configmap (i.e. a Docker .env file).'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -r -l from-env-file -d 'Specify the path to a file to read lines of key=val pairs to create a configmap (i.e. a Docker .env file).'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -r -l from-file -d 'Key file can be specified using its file path, in which case file basename will be used as configmap key, or optionally with a key and file path, in which case the given key will be used.  Specifying a directory will iterate each named file in the directory whose basename is a valid configmap key.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -r -l from-file -d 'Key file can be specified using its file path, in which case file basename will be used as configmap key, or optionally with a key and file path, in which case the given key will be used.  Specifying a directory will iterate each named file in the directory whose basename is a valid configmap key.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -r -l from-literal -d 'Specify a key and literal value to insert in configmap (i.e. mykey=somevalue)'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -r -l from-literal -d 'Specify a key and literal value to insert in configmap (i.e. mykey=somevalue)'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create configmap' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create cm' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create configmap' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cm' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create cronjob" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -r -l image -d 'Image name to run.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -r -l image -d 'Image name to run.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -r -l restart -d 'job\'s restart policy. supported values: OnFailure, Never'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -r -l restart -d 'job\'s restart policy. supported values: OnFailure, Never'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -r -l schedule -d 'A schedule in the Cron format the job should be run with.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -r -l schedule -d 'A schedule in the Cron format the job should be run with.'
complete -c kubectl -n '__fish_seen_subcommand_from create cronjob' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create cj' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cronjob' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create cj' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create deployment" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -r -l image -d 'Image names to run.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -r -l image -d 'Image names to run.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -r -l port -d 'The port that this container exposes.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -r -l port -d 'The port that this container exposes.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -r -s r -l replicas -d 'Number of replicas to create. Default is 1.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -r -s r -l replicas -d 'Number of replicas to create. Default is 1.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create deployment' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create deploy' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deployment' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create deploy' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create ingress" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -l annotation -d 'Annotation to insert in the ingress object, in the format annotation=value'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -l annotation -d 'Annotation to insert in the ingress object, in the format annotation=value'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -l class -d 'Ingress Class to be used'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -l class -d 'Ingress Class to be used'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -l default-backend -d 'Default service for backend, in format of svcname:port'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -l default-backend -d 'Default service for backend, in format of svcname:port'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -r -l rule -d 'Rule in format host/path=service:port[,tls=secretname]. Paths containing the leading character \'*\' are considered pathType=Prefix. tls argument is optional.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -r -l rule -d 'Rule in format host/path=service:port[,tls=secretname]. Paths containing the leading character \'*\' are considered pathType=Prefix. tls argument is optional.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create ingress' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create ing' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ingress' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ing' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create job" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -r -l from -d 'The name of the resource to create a Job from (only cronjob is supported).'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -r -l image -d 'Image name to run.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create job' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create job' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create namespace" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create namespace' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ns' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create namespace' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ns' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create namespace' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ns' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create namespace' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ns' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create namespace' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ns' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create namespace' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create ns' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create namespace' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create ns' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create poddisruptionbudget" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -l max-unavailable -d 'The maximum number or percentage of unavailable pods this budget requires.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -r -l max-unavailable -d 'The maximum number or percentage of unavailable pods this budget requires.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -l min-available -d 'The minimum number or percentage of available pods this budget requires.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -r -l min-available -d 'The minimum number or percentage of available pods this budget requires.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -l selector -d 'A label selector to use for this budget. Only equality-based selector requirements are supported.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -r -l selector -d 'A label selector to use for this budget. Only equality-based selector requirements are supported.'
complete -c kubectl -n '__fish_seen_subcommand_from create poddisruptionbudget' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create pdb' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create poddisruptionbudget' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pdb' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create priorityclass" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -r -l description -d 'description is an arbitrary string that usually provides guidelines on when this priority class should be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -r -l description -d 'description is an arbitrary string that usually provides guidelines on when this priority class should be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -l global-default -d 'global-default specifies whether this PriorityClass should be considered as the default priority.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -l global-default -d 'global-default specifies whether this PriorityClass should be considered as the default priority.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -r -l preemption-policy -d 'preemption-policy is the policy for preempting pods with lower priority.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -r -l preemption-policy -d 'preemption-policy is the policy for preempting pods with lower priority.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create priorityclass' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create pc' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create priorityclass' -r -l value -d 'the value of this priority class.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create pc' -r -l value -d 'the value of this priority class.'

# Completions for the "kubectl create quota" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -r -l hard -d 'A comma-delimited set of resource=quantity pairs that define a hard limit.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -r -l hard -d 'A comma-delimited set of resource=quantity pairs that define a hard limit.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -r -l scopes -d 'A comma-delimited set of quota scopes that must all match each object tracked by the quota.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -r -l scopes -d 'A comma-delimited set of quota scopes that must all match each object tracked by the quota.'
complete -c kubectl -n '__fish_seen_subcommand_from create quota' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create resourcequota' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create quota' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create resourcequota' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create role" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -r -l resource -d 'Resource that the rule applies to'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -r -l resource-name -d 'Resource in the white list that the rule applies to, repeat this flag for multiple items'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create role' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create role' -r -l verb -d 'Verb that applies to the resources contained in the rule'

# Completions for the "kubectl create rolebinding" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -l clusterrole -d 'ClusterRole this RoleBinding should reference'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -l group -d 'Groups to bind to the role'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -l role -d 'Role this RoleBinding should reference'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -r -l serviceaccount -d 'Service accounts to bind to the role, in the format <namespace>:<name>'
complete -c kubectl -n '__fish_seen_subcommand_from create rolebinding' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create rolebinding' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create secret" command
function __fish_kubectl_get_create_secret_commands
  echo docker-registry\t'Create a secret for use with a Docker registry'
  echo generic\t'Create a secret from a local file, directory or literal value'
  echo tls\t'Create a TLS secret'
end

function __fish_kubectl_get_create_secret_commands_without_descriptions
  __fish_kubectl_get_create_secret_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command secret; and not __fish_seen_subcommand_from (__fish_kubectl_get_create_secret_commands_without_descriptions)" -a '(__fish_kubectl_get_create_secret_commands)'

# Completions for the "kubectl create secret docker-registry" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -l append-hash -d 'Append a hash of the secret to its name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l docker-email -d 'Email for Docker registry'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l docker-password -d 'Password for Docker registry authentication'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l docker-server -d 'Server location for Docker registry'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l docker-username -d 'Username for Docker registry authentication'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -l from-file -d 'Key files can be specified using their file path, in which case a default name will be given to them, or optionally with a name and file path, in which case the given name will be used.  Specifying a directory will iterate each named file in the directory that is a valid secret key.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create secret docker-registry' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret docker-registry' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create secret generic" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -l append-hash -d 'Append a hash of the secret to its name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -l from-env-file -d 'Specify the path to a file to read lines of key=val pairs to create a secret (i.e. a Docker .env file).'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -l from-file -d 'Key files can be specified using their file path, in which case a default name will be given to them, or optionally with a name and file path, in which case the given name will be used.  Specifying a directory will iterate each named file in the directory that is a valid secret key.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -l from-literal -d 'Specify a key and literal value to insert in secret (i.e. mykey=somevalue)'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create secret generic' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -r -l type -d 'The type of secret to create'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret generic' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create secret tls" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -l append-hash -d 'Append a hash of the secret to its name.'
complete -c kubectl -n '__fish_seen_subcommand_from create secret tls' -r -l cert -d 'Path to PEM encoded public key certificate.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from create secret tls' -r -l key -d 'Path to private key associated with given certificate.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create secret tls' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create secret tls' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create service" command
function __fish_kubectl_get_create_service_commands
  echo clusterip\t'Create a ClusterIP service.'
  echo externalname\t'Create an ExternalName service.'
  echo loadbalancer\t'Create a LoadBalancer service.'
  echo nodeport\t'Create a NodePort service.'
end

function __fish_kubectl_get_create_service_commands_without_descriptions
  __fish_kubectl_get_create_service_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command service; and not __fish_seen_subcommand_from (__fish_kubectl_get_create_service_commands_without_descriptions)" -a '(__fish_kubectl_get_create_service_commands)'
complete -c kubectl -f -n "__fish_kubectl_using_command svc; and not __fish_seen_subcommand_from (__fish_kubectl_get_create_service_commands_without_descriptions)" -a '(__fish_kubectl_get_create_service_commands)'

# Completions for the "kubectl create service clusterip" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -r -l clusterip -d 'Assign your own ClusterIP or set to \'None\' for a \'headless\' service (no loadbalancing).'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -r -l tcp -d 'Port pairs can be specified as \'<port>:<targetPort>\'.'
complete -c kubectl -n '__fish_seen_subcommand_from create service clusterip' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service clusterip' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create service externalname" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -r -l external-name -d 'External name of service'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -r -l tcp -d 'Port pairs can be specified as \'<port>:<targetPort>\'.'
complete -c kubectl -n '__fish_seen_subcommand_from create service externalname' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service externalname' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create service loadbalancer" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -r -l tcp -d 'Port pairs can be specified as \'<port>:<targetPort>\'.'
complete -c kubectl -n '__fish_seen_subcommand_from create service loadbalancer' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service loadbalancer' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create service nodeport" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -r -l node-port -d 'Port used to expose the service on each node in a cluster.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -r -l tcp -d 'Port pairs can be specified as \'<port>:<targetPort>\'.'
complete -c kubectl -n '__fish_seen_subcommand_from create service nodeport' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create service nodeport' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl create serviceaccount" command
complete -c kubectl -f -n '__fish_seen_subcommand_from create serviceaccount' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create sa' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create serviceaccount' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create sa' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create serviceaccount' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create sa' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create serviceaccount' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create sa' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create serviceaccount' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from create sa' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from create serviceaccount' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from create sa' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from create serviceaccount' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from create sa' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl debug" command
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -l arguments-only -d 'If specified, everything after -- will be passed to the new container as Args instead of Command.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -l attach -d 'If true, wait for the container to start running, and then attach as if \'kubectl attach ...\' were called.  Default false, unless \'-i/--stdin\' is set, in which case the default is true.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -s c -l container -d 'Container name to use for debug container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -l copy-to -d 'Create a copy of the target Pod with this name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -l env -d 'Environment variables to set in the container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -l image -d 'Container image to use for debug container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -l image-pull-policy -d 'The image pull policy for the container. If left empty, this value will not be specified by the client and defaulted by the server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -l quiet -d 'If true, suppress informational messages.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -l replace -d 'When used with \'--copy-to\', delete the original Pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -l same-node -d 'When used with \'--copy-to\', schedule the copy of target Pod on the same node.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -l set-image -d 'When used with \'--copy-to\', a list of name=image pairs for changing container images, similar to how \'kubectl set image\' works.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -l share-processes -d 'When used with \'--copy-to\', enable process namespace sharing in the copy.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -s i -l stdin -d 'Keep stdin open on the container(s) in the pod, even if nothing is attached.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -r -l target -d 'When using an ephemeral container, target processes in this container name.'
complete -c kubectl -f -n '__fish_seen_subcommand_from debug' -s t -l tty -d 'Allocate a TTY for the debugging container.'

# Completions for the "kubectl delete" command
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -l all -d 'Delete all resources, including uninitialized ones, in the namespace of the specified resource types.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -l cascade -d 'Must be "background", "orphan", or "foreground". Selects the deletion cascading strategy for the dependents (e.g. Pods created by a ReplicationController). Defaults to background.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -l field-selector -d 'Selector (field query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. --field-selector key1=value1,key2=value2). The server only supports a limited number of field queries per type.'
complete -c kubectl -n '__fish_seen_subcommand_from delete' -r -s f -l filename -d 'containing the resource to delete.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -l force -d 'If true, immediately remove resources from API and bypass graceful deletion. Note that immediate deletion of some resources may result in inconsistency or data loss and requires confirmation.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -l grace-period -d 'Period of time in seconds given to the resource to terminate gracefully. Ignored if negative. Set to 1 for immediate shutdown. Can only be set to 0 when --force is true (force deletion).'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -l ignore-not-found -d 'Treat "resource not found" as a successful delete. Defaults to "true" when --all is specified.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -s k -l kustomize -d 'Process a kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -l now -d 'If true, resources are signaled for immediate shutdown (same as --grace-period=1).'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -s o -l output -d 'Output mode. Use "-o name" for shorter output (resource/name).'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -l raw -d 'Raw URI to DELETE to the server.  Uses the transport specified by the kubeconfig file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -s l -l selector -d 'Selector (label query) to filter on, not including uninitialized ones.'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -r -l timeout -d 'The length of time to wait before giving up on a delete, zero means determine a timeout from the size of the object'
complete -c kubectl -f -n '__fish_seen_subcommand_from delete' -l wait -d 'If true, wait for resources to be gone before returning. This waits for finalizers.'

# Completions for the "kubectl describe" command
complete -c kubectl -f -n '__fish_seen_subcommand_from describe' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -n '__fish_seen_subcommand_from describe' -r -s f -l filename -d 'Filename, directory, or URL to files containing the resource to describe'
complete -c kubectl -f -n '__fish_seen_subcommand_from describe' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from describe' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from describe' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from describe' -l show-events -d 'If true, display events related to the described object.'

# Completions for the "kubectl diff" command
complete -c kubectl -f -n '__fish_seen_subcommand_from diff' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from diff' -r -s f -l filename -d 'Filename, directory, or URL to files contains the configuration to diff'
complete -c kubectl -f -n '__fish_seen_subcommand_from diff' -l force-conflicts -d 'If true, server-side apply will force the changes against conflicts.'
complete -c kubectl -f -n '__fish_seen_subcommand_from diff' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from diff' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from diff' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from diff' -l server-side -d 'If true, apply runs in the server instead of the client.'

# Completions for the "kubectl drain" command
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -l delete-emptydir-data -d 'Continue even if there are pods using emptyDir (local data that will be deleted when the node is drained).'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -l disable-eviction -d 'Force drain to use delete, even if eviction is supported. This will bypass checking PodDisruptionBudgets, use with caution.'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -l force -d 'Continue even if there are pods not managed by a ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet.'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -r -l grace-period -d 'Period of time in seconds given to each pod to terminate gracefully. If negative, the default value specified in the pod will be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -l ignore-daemonsets -d 'Ignore DaemonSet-managed pods.'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -r -l pod-selector -d 'Label selector to filter pods on the node'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -r -s l -l selector -d 'Selector (label query) to filter on'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -r -l skip-wait-for-delete-timeout -d 'If pod DeletionTimestamp older than N seconds, skip waiting for the pod.  Seconds must be greater than 0 to skip.'
complete -c kubectl -f -n '__fish_seen_subcommand_from drain' -r -l timeout -d 'The length of time to wait before giving up, zero means infinite'

# Completions for the "kubectl edit" command
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from edit' -r -s f -l filename -d 'Filename, directory, or URL to files to use to edit the resource'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -l output-patch -d 'Output the patch if the resource is edited.'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from edit' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from edit' -l windows-line-endings -d 'Defaults to the line ending native to your platform.'

# Completions for the "kubectl exec" command
complete -c kubectl -f -n '__fish_seen_subcommand_from exec' -r -s c -l container -d 'Container name. If omitted, the first container in the pod will be chosen'
complete -c kubectl -n '__fish_seen_subcommand_from exec' -r -s f -l filename -d 'to use to exec into the resource'
complete -c kubectl -f -n '__fish_seen_subcommand_from exec' -r -l pod-running-timeout -d 'The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running'
complete -c kubectl -f -n '__fish_seen_subcommand_from exec' -s i -l stdin -d 'Pass stdin to the container'
complete -c kubectl -f -n '__fish_seen_subcommand_from exec' -s t -l tty -d 'Stdin is a TTY'

# Completions for the "kubectl explain" command
complete -c kubectl -f -n '__fish_seen_subcommand_from explain' -r -l api-version -d 'Get different explanations for particular API version (API group/version)'
complete -c kubectl -f -n '__fish_seen_subcommand_from explain' -l recursive -d 'Print the fields of fields (Currently only 1 level deep)'

# Completions for the "kubectl expose" command
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l cluster-ip -d 'ClusterIP to be assigned to the service. Leave empty to auto-allocate, or set to \'None\' to create a headless service.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l external-ip -d 'Additional external IP address (not managed by Kubernetes) to accept for the service. If this IP is routed to a node, the service can be accessed by this IP in addition to its generated service IP.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from expose' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to expose a service'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l generator -d 'The name of the API generator to use. There are 2 generators: \'service/v1\' and \'service/v2\'. The only difference between them is that service port in v1 is named \'default\', while it is left unnamed in v2. Default is \'service/v2\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -s l -l labels -d 'Labels to apply to the service created by this call.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l load-balancer-ip -d 'IP to assign to the LoadBalancer. If empty, an ephemeral IP will be created and used (cloud-provider specific).'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l name -d 'The name for the newly created object.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l overrides -d 'An inline JSON override for the generated object. If this is non-empty, it is used to override the generated object. Requires that the object supply a valid apiVersion field.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l port -d 'The port that the service should serve on. Copied from the resource being exposed, if unspecified'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l protocol -d 'The network protocol for the service to be created. Default is \'TCP\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l selector -d 'A label selector to use for this service. Only equality-based selector requirements are supported. If empty (the default) infer the selector from the replication controller or replica set.)'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l session-affinity -d 'If non-empty, set the session affinity for the service to this; legal values: \'None\', \'ClientIP\''
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l target-port -d 'Name or number for the port on the container that the service should direct traffic to. Optional.'
complete -c kubectl -n '__fish_seen_subcommand_from expose' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from expose' -r -l type -d 'Type for this service: ClusterIP, NodePort, LoadBalancer, or ExternalName. Default is \'ClusterIP\'.'

# Completions for the "kubectl get" command
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -l chunk-size -d 'Return large lists in chunks rather than all at once. Pass 0 to disable. This flag is beta and may change in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -l field-selector -d 'Selector (field query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. --field-selector key1=value1,key2=value2). The server only supports a limited number of field queries per type.'
complete -c kubectl -n '__fish_seen_subcommand_from get' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l ignore-not-found -d 'If the requested object does not exist the command will return exit code 0.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -s L -l label-columns -d 'Accepts a comma separated list of labels that are going to be presented as columns. Names are case-sensitive. You can also use multiple flag options like -L label1 -L label2...'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l no-headers -d 'When using the default or custom-column output format, don\'t print headers (default print headers).'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -s o -l output -d 'Output format. One of: json|yaml|wide|name|custom-columns=...|custom-columns-file=...|go-template=...|go-template-file=...|jsonpath=...|jsonpath-file=... See custom columns [http://kubernetes.io/docs/user-guide/kubectl-overview/#custom-columns], golang template [http://golang.org/pkg/text/template/#pkg-overview] and jsonpath template [http://kubernetes.io/docs/user-guide/jsonpath].'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l output-watch-events -d 'Output watch event objects when --watch or --watch-only is used. Existing objects are output as initial ADDED events.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -l raw -d 'Raw URI to request from the server.  Uses the transport specified by the kubeconfig file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l server-print -d 'If true, have the server return the appropriate table output. Supports extension APIs and CRDs.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l show-kind -d 'If present, list the resource type for the requested object(s).'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l show-labels -d 'When printing, show all labels as the last column (default hide labels column)'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -r -l sort-by -d 'If non-empty, sort list types using this field specification.  The field specification is expressed as a JSONPath expression (e.g. \'{.metadata.name}\'). The field in the API resource specified by this JSONPath expression must be an integer or a string.'
complete -c kubectl -n '__fish_seen_subcommand_from get' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -s w -l watch -d 'After listing/getting the requested object, watch for changes. Uninitialized objects are excluded if no object name is provided.'
complete -c kubectl -f -n '__fish_seen_subcommand_from get' -l watch-only -d 'Watch for changes to the requested object(s), without listing/getting first.'

# Completions for the "kubectl label" command
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -l field-selector -d 'Selector (field query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. --field-selector key1=value1,key2=value2). The server only supports a limited number of field queries per type.'
complete -c kubectl -n '__fish_seen_subcommand_from label' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to update the labels'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -l list -d 'If true, display the labels for a given resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -l local -d 'If true, label will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -l overwrite -d 'If true, allow labels to be overwritten, otherwise reject label updates that overwrite existing labels.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -l resource-version -d 'If non-empty, the labels update will only succeed if this is the current resource-version for the object. Only valid when specifying a single resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from label' -r -s l -l selector -d 'Selector (label query) to filter on, not including uninitialized ones, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2).'
complete -c kubectl -n '__fish_seen_subcommand_from label' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl logs" command
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -l all-containers -d 'Get all containers\' logs in the pod(s).'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -s c -l container -d 'Print the logs of this container'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -s f -l follow -d 'Specify if the logs should be streamed.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -l ignore-errors -d 'If watching / following pod logs, allow for any errors that occur to be non-fatal'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -l insecure-skip-tls-verify-backend -d 'Skip verifying the identity of the kubelet that logs are requested from.  In theory, an attacker could provide invalid log content back. You might want to use this if your kubelet serving certificates have expired.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -l limit-bytes -d 'Maximum bytes of logs to return. Defaults to no limit.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -l max-log-requests -d 'Specify maximum number of concurrent logs to follow when using by a selector. Defaults to 5.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -l pod-running-timeout -d 'The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -l prefix -d 'Prefix each log line with the log source (pod name and container name)'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -s p -l previous -d 'If true, print the logs for the previous instance of the container in a pod if it exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -s l -l selector -d 'Selector (label query) to filter on.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -l since -d 'Only return logs newer than a relative duration like 5s, 2m, or 3h. Defaults to all logs. Only one of since-time / since may be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -l since-time -d 'Only return logs after a specific date (RFC3339). Defaults to all logs. Only one of since-time / since may be used.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -r -l tail -d 'Lines of recent log file to display. Defaults to -1 with no selector, showing all log lines otherwise 10, if a selector is provided.'
complete -c kubectl -f -n '__fish_seen_subcommand_from logs' -l timestamps -d 'Include timestamps on each line in the log output'

# Completions for the "kubectl patch" command
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from patch' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to update'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -l local -d 'If true, patch will operate on the content of the file, not the server-side resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -s p -l patch -d 'The patch to be applied to the resource JSON file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -l patch-file -d 'A file containing a patch to be applied to the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from patch' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from patch' -r -l type -d 'The type of patch being provided; one of [json merge strategic]'

# Completions for the "kubectl plugin" command
function __fish_kubectl_get_plugin_commands
  echo list\t'list all visible plugin executables on a user\'s PATH'
end

function __fish_kubectl_get_plugin_commands_without_descriptions
  __fish_kubectl_get_plugin_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command plugin; and not __fish_seen_subcommand_from (__fish_kubectl_get_plugin_commands_without_descriptions)" -a '(__fish_kubectl_get_plugin_commands)'

# Completions for the "kubectl plugin list" command
complete -c kubectl -f -n '__fish_seen_subcommand_from plugin list' -l name-only -d 'If true, display only the binary name of each plugin, rather than its full path'

# Completions for the "kubectl port-forward" command
complete -c kubectl -f -n '__fish_seen_subcommand_from port-forward' -r -l address -d 'Addresses to listen on (comma separated). Only accepts IP addresses or localhost as a value. When localhost is supplied, kubectl will try to bind on both 127.0.0.1 and ::1 and will fail if neither of these addresses are available to bind.'
complete -c kubectl -f -n '__fish_seen_subcommand_from port-forward' -r -l pod-running-timeout -d 'The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running'

# Completions for the "kubectl proxy" command
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l accept-hosts -d 'Regular expression for hosts that the proxy should accept.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l accept-paths -d 'Regular expression for paths that the proxy should accept.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l address -d 'The IP address on which to serve on.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l api-prefix -d 'Prefix to serve the proxied API under.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -l disable-filter -d 'If true, disable request filtering in the proxy. This is dangerous, and can leave you vulnerable to XSRF attacks, when used with an accessible port.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l keepalive -d 'keepalive specifies the keep-alive period for an active network connection. Set to 0 to disable keepalive.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -s p -l port -d 'The port on which to run the proxy. Set to 0 to pick a random port.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l reject-methods -d 'Regular expression for HTTP methods that the proxy should reject (example --reject-methods=\'POST,PUT,PATCH\'). '
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -l reject-paths -d 'Regular expression for paths that the proxy should reject. Paths specified here will be rejected even accepted by --accept-paths.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -s u -l unix-socket -d 'Unix socket on which to run the proxy.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -s w -l www -d 'Also serve static files from the given directory under the specified prefix.'
complete -c kubectl -f -n '__fish_seen_subcommand_from proxy' -r -s P -l www-prefix -d 'Prefix to serve static files under, if static file directory is specified.'

# Completions for the "kubectl replace" command
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -l cascade -d 'Must be "background", "orphan", or "foreground". Selects the deletion cascading strategy for the dependents (e.g. Pods created by a ReplicationController). Defaults to background.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from replace' -r -s f -l filename -d 'to use to replace the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -l force -d 'If true, immediately remove resources from API and bypass graceful deletion. Note that immediate deletion of some resources may result in inconsistency or data loss and requires confirmation.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -l grace-period -d 'Period of time in seconds given to the resource to terminate gracefully. Ignored if negative. Set to 1 for immediate shutdown. Can only be set to 0 when --force is true (force deletion).'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -s k -l kustomize -d 'Process a kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -l raw -d 'Raw URI to PUT to the server.  Uses the transport specified by the kubeconfig file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -n '__fish_seen_subcommand_from replace' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -r -l timeout -d 'The length of time to wait before giving up on a delete, zero means determine a timeout from the size of the object'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -l validate -d 'If true, use a schema to validate the input before sending it'
complete -c kubectl -f -n '__fish_seen_subcommand_from replace' -l wait -d 'If true, wait for resources to be gone before returning. This waits for finalizers.'

# Completions for the "kubectl rollout" command
function __fish_kubectl_get_rollout_commands
  echo history\t'View rollout history'
  echo pause\t'Mark the provided resource as paused'
  echo restart\t'Restart a resource'
  echo resume\t'Resume a paused resource'
  echo status\t'Show the status of the rollout'
  echo undo\t'Undo a previous rollout'
end

function __fish_kubectl_get_rollout_commands_without_descriptions
  __fish_kubectl_get_rollout_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command rollout; and not __fish_seen_subcommand_from (__fish_kubectl_get_rollout_commands_without_descriptions)" -a '(__fish_kubectl_get_rollout_commands)'

# Completions for the "kubectl rollout history" command
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout history' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout history' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout history' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout history' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout history' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout history' -r -l revision -d 'See the details, including podTemplate of the revision specified'
complete -c kubectl -n '__fish_seen_subcommand_from rollout history' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl rollout pause" command
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout pause' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout pause' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout pause' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout pause' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout pause' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout pause' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout pause' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl rollout restart" command
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout restart' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout restart' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout restart' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout restart' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout restart' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout restart' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout restart' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl rollout resume" command
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout resume' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout resume' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout resume' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout resume' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout resume' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout resume' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout resume' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl rollout status" command
complete -c kubectl -n '__fish_seen_subcommand_from rollout status' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout status' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout status' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout status' -r -l revision -d 'Pin to a specific revision for showing its status. Defaults to 0 (last revision).'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout status' -r -l timeout -d 'The length of time to wait before ending watch, zero means never. Any other values should contain a corresponding time unit (e.g. 1s, 2m, 3h).'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout status' -s w -l watch -d 'Watch the status of the rollout until it\'s done.'

# Completions for the "kubectl rollout undo" command
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout undo' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout undo' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout undo' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout undo' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout undo' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout undo' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from rollout undo' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from rollout undo' -r -l to-revision -d 'The revision to rollback to. Default to 0 (last revision).'

# Completions for the "kubectl run" command
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l annotations -d 'Annotations to apply to the pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l attach -d 'If true, wait for the Pod to start running, and then attach to the Pod as if \'kubectl attach ...\' were called.  Default false, unless \'-i/--stdin\' is set, in which case the default is true. With \'--restart=Never\' the exit code of the container process is returned.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l cascade -d 'Must be "background", "orphan", or "foreground". Selects the deletion cascading strategy for the dependents (e.g. Pods created by a ReplicationController). Defaults to background.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l command -d 'If true and extra arguments are present, use them as the \'command\' field in the container, rather than the \'args\' field which is the default.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l env -d 'Environment variables to set in the container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l expose -d 'If true, service is created for the container(s) which are run'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from run' -r -s f -l filename -d 'to use to replace the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l force -d 'If true, immediately remove resources from API and bypass graceful deletion. Note that immediate deletion of some resources may result in inconsistency or data loss and requires confirmation.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l grace-period -d 'Period of time in seconds given to the resource to terminate gracefully. Ignored if negative. Set to 1 for immediate shutdown. Can only be set to 0 when --force is true (force deletion).'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l hostport -d 'The host port mapping for the container port. To demonstrate a single-machine container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l image -d 'The image for the container to run.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l image-pull-policy -d 'The image pull policy for the container. If left empty, this value will not be specified by the client and defaulted by the server'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -s k -l kustomize -d 'Process a kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -s l -l labels -d 'Comma separated labels to apply to the pod(s). Will override previous values.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l leave-stdin-open -d 'If the pod is started in interactive mode or with stdin, leave stdin open after the first attach completes. By default, stdin will be closed after the first attach completes.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l limits -d 'The resource requirement limits for this container.  For example, \'cpu=200m,memory=512Mi\'.  Note that server side components may assign limits depending on the server configuration, such as limit ranges.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l overrides -d 'An inline JSON override for the generated object. If this is non-empty, it is used to override the generated object. Requires that the object supply a valid apiVersion field.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l pod-running-timeout -d 'The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one pod is running'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l port -d 'The port that this container exposes.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l privileged -d 'If true, run the container in privileged mode.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l quiet -d 'If true, suppress prompt messages.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l requests -d 'The resource requirement requests for this container.  For example, \'cpu=100m,memory=256Mi\'.  Note that server side components may assign requests depending on the server configuration, such as limit ranges.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l restart -d 'The restart policy for this Pod.  Legal values [Always, OnFailure, Never].'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l rm -d 'If true, delete resources created in this command for attached containers.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l save-config -d 'If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l serviceaccount -d 'Service account to set in the pod spec.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -s i -l stdin -d 'Keep stdin open on the container(s) in the pod, even if nothing is attached.'
complete -c kubectl -n '__fish_seen_subcommand_from run' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -r -l timeout -d 'The length of time to wait before giving up on a delete, zero means determine a timeout from the size of the object'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -s t -l tty -d 'Allocated a TTY for each container in the pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from run' -l wait -d 'If true, wait for resources to be gone before returning. This waits for finalizers.'

# Completions for the "kubectl scale" command
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -l all -d 'Select all resources in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -l current-replicas -d 'Precondition for current size. Requires that the current size of the resource match this value in order to scale.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -n '__fish_seen_subcommand_from scale' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to set a new size'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -l replicas -d 'The new desired number of replicas. Required.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -l resource-version -d 'Precondition for resource version. Requires that the current resource version match this value in order to scale.'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -n '__fish_seen_subcommand_from scale' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from scale' -r -l timeout -d 'The length of time to wait before giving up on a scale operation, zero means don\'t wait. Any other values should contain a corresponding time unit (e.g. 1s, 2m, 3h).'

# Completions for the "kubectl set" command
function __fish_kubectl_get_set_commands
  echo env\t'Update environment variables on a pod template'
  echo image\t'Update image of a pod template'
  echo resources\t'Update resource requests/limits on objects with pod templates'
  echo selector\t'Set the selector on a resource'
  echo serviceaccount\t'Update ServiceAccount of a resource'
  echo sa\t'Update ServiceAccount of a resource'
  echo subject\t'Update User, Group or ServiceAccount in a RoleBinding/ClusterRoleBinding'
end

function __fish_kubectl_get_set_commands_without_descriptions
  __fish_kubectl_get_set_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command set; and not __fish_seen_subcommand_from (__fish_kubectl_get_set_commands_without_descriptions)" -a '(__fish_kubectl_get_set_commands)'

# Completions for the "kubectl set env" command
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -l all -d 'If true, select all resources in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -s c -l containers -d 'The names of containers in the selected pod templates to change - may use wildcards'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -s e -l env -d 'Specify a key-value pair for an environment variable to set into each container.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from set env' -r -s f -l filename -d 'Filename, directory, or URL to files the resource to update the env'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -l from -d 'The name of a resource from which to inject environment variables'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -l keys -d 'Comma-separated list of keys to import from specified resource'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -l list -d 'If true, display the environment and any changes in the standard format. this flag will removed when we have kubectl view env.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -l local -d 'If true, set env will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -l overwrite -d 'If true, allow environment to be overwritten, otherwise reject updates that overwrite existing environment.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -l prefix -d 'Prefix to append to variable names'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -l resolve -d 'If true, show secret or configmap references when listing variables'
complete -c kubectl -f -n '__fish_seen_subcommand_from set env' -r -s l -l selector -d 'Selector (label query) to filter on'
complete -c kubectl -n '__fish_seen_subcommand_from set env' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl set image" command
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from set image' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -l local -d 'If true, set image will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set image' -r -s l -l selector -d 'Selector (label query) to filter on, not including uninitialized ones, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -n '__fish_seen_subcommand_from set image' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl set resources" command
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -s c -l containers -d 'The names of containers in the selected pod templates to change, all containers are selected by default - may use wildcards'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from set resources' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -l limits -d 'The resource requirement requests for this container.  For example, \'cpu=100m,memory=256Mi\'.  Note that server side components may assign requests depending on the server configuration, such as limit ranges.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -l local -d 'If true, set resources will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -l requests -d 'The resource requirement requests for this container.  For example, \'cpu=100m,memory=256Mi\'.  Note that server side components may assign requests depending on the server configuration, such as limit ranges.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set resources' -r -s l -l selector -d 'Selector (label query) to filter on, not including uninitialized ones,supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -n '__fish_seen_subcommand_from set resources' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl set selector" command
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -l all -d 'Select all resources in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from set selector' -r -s f -l filename -d 'identifying the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -l local -d 'If true, annotation will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set selector' -r -l resource-version -d 'If non-empty, the selectors update will only succeed if this is the current resource-version for the object. Only valid when specifying a single resource.'
complete -c kubectl -n '__fish_seen_subcommand_from set selector' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl set serviceaccount" command
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from set serviceaccount' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -n '__fish_seen_subcommand_from set sa' -r -s f -l filename -d 'Filename, directory, or URL to files identifying the resource to get from a server.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -l local -d 'If true, set serviceaccount will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -l local -d 'If true, set serviceaccount will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -l record -d 'Record current kubectl command in the resource annotation. If set to false, do not record the command. If set to true, record the command. If not set, default to updating the existing annotation value only if one already exists.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set serviceaccount' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set sa' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -n '__fish_seen_subcommand_from set serviceaccount' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -n '__fish_seen_subcommand_from set sa' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl set subject" command
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -l all -d 'Select all resources, including uninitialized ones, in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -n '__fish_seen_subcommand_from set subject' -r -s f -l filename -d 'Filename, directory, or URL to files the resource to update the subjects'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -l group -d 'Groups to bind to the role'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -s k -l kustomize -d 'Process the kustomization directory. This flag can\'t be used together with -f or -R.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -l local -d 'If true, set subject will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -s l -l selector -d 'Selector (label query) to filter on, not including uninitialized ones, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from set subject' -r -l serviceaccount -d 'Service accounts to bind to the role'
complete -c kubectl -n '__fish_seen_subcommand_from set subject' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'

# Completions for the "kubectl taint" command
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -l all -d 'Select all nodes in the cluster'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -r -l field-manager -d 'Name of the manager used to track field ownership.'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -l overwrite -d 'If true, allow taints to be overwritten, otherwise reject taint updates that overwrite existing taints.'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -n '__fish_seen_subcommand_from taint' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from taint' -l validate -d 'If true, use a schema to validate the input before sending it'

# Completions for the "kubectl top" command
function __fish_kubectl_get_top_commands
  echo node\t'Display Resource (CPU/Memory/Storage) usage of nodes'
  echo nodes\t'Display Resource (CPU/Memory/Storage) usage of nodes'
  echo no\t'Display Resource (CPU/Memory/Storage) usage of nodes'
  echo pod\t'Display Resource (CPU/Memory/Storage) usage of pods'
  echo pods\t'Display Resource (CPU/Memory/Storage) usage of pods'
  echo po\t'Display Resource (CPU/Memory/Storage) usage of pods'
end

function __fish_kubectl_get_top_commands_without_descriptions
  __fish_kubectl_get_top_commands | string replace -r '\t.*$' ''
end

complete -c kubectl -f -n "__fish_kubectl_using_command top; and not __fish_seen_subcommand_from (__fish_kubectl_get_top_commands_without_descriptions)" -a '(__fish_kubectl_get_top_commands)'

# Completions for the "kubectl top node" command
complete -c kubectl -f -n '__fish_seen_subcommand_from top node' -l no-headers -d 'If present, print output without headers'
complete -c kubectl -f -n '__fish_seen_subcommand_from top nodes' -l no-headers -d 'If present, print output without headers'
complete -c kubectl -f -n '__fish_seen_subcommand_from top no' -l no-headers -d 'If present, print output without headers'
complete -c kubectl -f -n '__fish_seen_subcommand_from top node' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from top nodes' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from top no' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from top node' -r -l sort-by -d 'If non-empty, sort nodes list using specified field. The field can be either \'cpu\' or \'memory\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top nodes' -r -l sort-by -d 'If non-empty, sort nodes list using specified field. The field can be either \'cpu\' or \'memory\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top no' -r -l sort-by -d 'If non-empty, sort nodes list using specified field. The field can be either \'cpu\' or \'memory\'.'

# Completions for the "kubectl top pod" command
complete -c kubectl -f -n '__fish_seen_subcommand_from top pod' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pods' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top po' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pod' -l containers -d 'If present, print usage of containers within a pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pods' -l containers -d 'If present, print usage of containers within a pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top po' -l containers -d 'If present, print usage of containers within a pod.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pod' -l no-headers -d 'If present, print output without headers.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pods' -l no-headers -d 'If present, print output without headers.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top po' -l no-headers -d 'If present, print output without headers.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pod' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pods' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from top po' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pod' -r -l sort-by -d 'If non-empty, sort pods list using specified field. The field can be either \'cpu\' or \'memory\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top pods' -r -l sort-by -d 'If non-empty, sort pods list using specified field. The field can be either \'cpu\' or \'memory\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from top po' -r -l sort-by -d 'If non-empty, sort pods list using specified field. The field can be either \'cpu\' or \'memory\'.'

# Completions for the "kubectl uncordon" command
complete -c kubectl -f -n '__fish_seen_subcommand_from uncordon' -r -l dry-run -d 'Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without sending it. If server strategy, submit server-side request without persisting the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from uncordon' -r -s l -l selector -d 'Selector (label query) to filter on'

# Completions for the "kubectl version" command
complete -c kubectl -f -n '__fish_seen_subcommand_from version' -l client -d 'If true, shows client version only (no server required).'
complete -c kubectl -f -n '__fish_seen_subcommand_from version' -r -s o -l output -d 'One of \'yaml\' or \'json\'.'
complete -c kubectl -f -n '__fish_seen_subcommand_from version' -l short -d 'If true, print just the version number.'

# Completions for the "kubectl wait" command
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -l all -d 'Select all resources in the namespace of the specified resource types'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -s A -l all-namespaces -d 'If present, list the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -l allow-missing-template-keys -d 'If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -r -l field-selector -d 'Selector (field query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. --field-selector key1=value1,key2=value2). The server only supports a limited number of field queries per type.'
complete -c kubectl -n '__fish_seen_subcommand_from wait' -r -s f -l filename -d 'identifying the resource.'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -r -l for -d 'The condition to wait on: [delete|condition=condition-name].'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -l local -d 'If true, annotation will NOT contact api-server but run locally.'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -r -s o -l output -d 'Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -s R -l recursive -d 'Process the directory used in -f, --filename recursively. Useful when you want to manage related manifests organized within the same directory.'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -r -s l -l selector -d 'Selector (label query) to filter on, supports \'=\', \'==\', and \'!=\'.(e.g. -l key1=value1,key2=value2)'
complete -c kubectl -n '__fish_seen_subcommand_from wait' -r -l template -d 'Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview].'
complete -c kubectl -f -n '__fish_seen_subcommand_from wait' -r -l timeout -d 'The length of time to wait before giving up.  Zero means check once and don\'t wait, negative means wait for a week.'
