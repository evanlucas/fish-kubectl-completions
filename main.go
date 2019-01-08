package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
	k8scmd "k8s.io/kubernetes/pkg/kubectl/cmd"
)

const (
	fishCompletionFunc = `#
set -q FISH_KUBECTL_COMPLETION_TIMEOUT; or set FISH_KUBECTL_COMPLETION_TIMEOUT 5s
set __fish_kubectl_timeout "--request-timeout=$FISH_KUBECTL_COMPLETION_TIMEOUT"
set __fish_kubectl_all_namespaces_flags "--all-namespaces" "--all-namespaces=true"
set __fish_kubectl_subresource_commands get describe delete edit label explain
set __fish_kubectl_commands %s

function __fish_kubectl
  command kubectl $__fish_kubectl_timeout $argv
end

function __fish_kubectl_get_commands
%s
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

function __fish_kubectl_get_crds
  __fish_kubectl get crd -o jsonpath='{range .items[*]}{.spec.names.plural}{"\n"}{.spec.names.singular}{"\n"}{end}'
end

function __fish_kubectl_seen_subcommand_from_regex
  set -l cmd (commandline -poc)
  set -e cmd[1]
  for i in $cmd
    for r in $argv
      if string match -r $r $i
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
  if not set -l matches (string match "(.*)/" $last)
    return
  end

  if string match -q "(.*)/" $last
    return 0
  end

  return 1
end

function __fish_kubectl_print_matching_resources
  set -l last (commandline -opt)
  if not set -l matches (string match -r "(.*)/" $last)
    return
  end
  set -l prefix $matches[2]
  set -l resources (__fish_kubectl_print_resource "$prefix")
  for i in $resources
    echo "$prefix/$i"
  end
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

  set -l crds (__fish_kubectl_get_crds)

  for r in $crds
    echo $r
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

  set args $args get "$resource" -o name
  __fish_kubectl $args | string replace -r '(.*)/' ''
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

  set -l deploys (__fish_kubectl $args get deploy -o jsonpath="$template")
  set -l daemonsets (__fish_kubectl $args get ds -o jsonpath="$template")
  set -l sts (__fish_kubectl $args get sts -o jsonpath="$template")

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

  complete -c kubectl -f -n "__fish_kubectl_using_command $subcmd; and __fish_seen_subcommand_from (__fish_kubectl_get_crds)" -a '(__fish_kubectl_print_current_resources)' -d 'CRD'
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
`
)

func main() {
	err := GenFishCompletion(os.Stdout)
	if err != nil {
		fmt.Println(err)
		return
	}
}

func GenFishCompletion(w io.Writer) error {
	buf := new(bytes.Buffer)
	root := k8scmd.NewKubectlCommand(os.Stdin, os.Stdout, os.Stderr)
	commands := []string{}
	commandsWithDescriptions := []string{}
	completions := new(bytes.Buffer)

	for _, cmd := range root.Commands() {
		names := strings.Split(cmd.NameAndAliases(), ", ")
		for _, name := range names {
			commands = append(commands, name)
			c := fmt.Sprintf("  echo %s\\t'%s'", name, cmd.Short)
			commandsWithDescriptions = append(commandsWithDescriptions, c)
		}

		completeCommand(completions, cmd)
	}
	writePreamble(buf, commands, commandsWithDescriptions)

	rootFlagCompletions := map[string]string{
		"namespace": "(__fish_kubectl_print_resource namespace)",
		"cluster":   "(__fish_kubectl_get_config clusters)",
		"context":   "(__fish_kubectl_get_config contexts)",
		"user":      "(__fish_kubectl_get_config users)",
	}

	root.NonInheritedFlags().VisitAll(func(flag *pflag.Flag) {
		if nonCompletableFlag(flag) {
			return
		}

		requiresArg := ""
		short := ""
		noFiles := " -f"

		if !flagIsBoolean(flag) {
			requiresArg = " -r"
		}

		if flag.Shorthand != "" {
			short = fmt.Sprintf(" -s %s", flag.Shorthand)
		}

		for key := range flag.Annotations {
			switch key {
			case cobra.BashCompFilenameExt:
				noFiles = ""
			}
		}

		if strings.HasPrefix(flag.Usage, "Path to") {
			noFiles = ""
		}

		if strings.HasSuffix(flag.Name, "-dir") {
			noFiles = ""
		}

		long := fmt.Sprintf(" -l %s", flag.Name)
		desc := fmt.Sprintf(" -d '%s'", strings.Replace(flag.Usage, "'", "\\'", -1))
		str := fmt.Sprintf("complete -c kubectl%s%s%s%s%s", noFiles, requiresArg, short, long, desc)
		if val, ok := rootFlagCompletions[flag.Name]; ok {
			str = fmt.Sprintf("%s -a '%s'", str, val)
		}

		buf.WriteString(str + "\n")
	})

	buf.WriteString(completions.String())
	_, err := buf.WriteTo(w)
	return err
}

func escapeQuotes(str string) string {
	return strings.Replace(str, "'", "\\'", -1)
}

func buildSubcommandCompletion(name string, functionName string) string {
	var b strings.Builder

	b.WriteString("complete -c kubectl -f -n \"__fish_kubectl_using_command ")
	withoutDescs := fmt.Sprintf("%s_without_descriptions", functionName)
	b.WriteString(fmt.Sprintf("%s; and not __fish_seen_subcommand_from (%s)\" ", name, withoutDescs))
	b.WriteString(fmt.Sprintf("-a '(%s)'\n", functionName))
	return b.String()
}

func buildFishList(cmd *cobra.Command) (string, string) {
	var b strings.Builder
	parents := getParents(cmd)
	n := strings.Join(parents, "_")
	clean := strings.Replace(n, "-", "_", -1)
	functionName := fmt.Sprintf("__fish_kubectl_get_%s_commands", clean)
	b.WriteString(fmt.Sprintf("function %s\n", functionName))
	for _, cmd := range cmd.Commands() {
		desc := escapeQuotes(cmd.Short)
		names := strings.Split(cmd.NameAndAliases(), ", ")
		for _, name := range names {
			c := fmt.Sprintf("  echo %s\\t'%s'\n", name, desc)
			b.WriteString(c)
		}
	}
	b.WriteString("end\n\n")

	b.WriteString(fmt.Sprintf("function %s_without_descriptions\n", functionName))
	b.WriteString(fmt.Sprintf("  %s | string replace -r '\\t.*$' ''\n", functionName))
	b.WriteString("end\n\n")
	return functionName, b.String()
}

func nonCompletableFlag(flag *pflag.Flag) bool {
	return flag.Hidden || len(flag.Deprecated) > 0
}

func writePreamble(buf *bytes.Buffer, commands []string, cmdDesc []string) {
	b := strings.Join(commands, " \\\n  ")
	withDesc := strings.Join(cmdDesc, "\n")
	buf.WriteString(fmt.Sprintf(fishCompletionFunc, b, withDesc))
}

func getParents(cmd *cobra.Command) []string {
	s := []string{cmd.Name()}
	cmd = cmd.Parent()
	for cmd.HasParent() {
		s = append([]string{cmd.Name()}, s...)
		cmd = cmd.Parent()
	}

	return s
}

func buildParentPath(name string, cmd *cobra.Command) string {
	s := []string{name}
	cmd = cmd.Parent()
	for cmd.HasParent() {
		s = append([]string{cmd.Name()}, s...)
		cmd = cmd.Parent()
	}

	return strings.Join(s, " ")
}

func buildParentCheck(name string, cmd *cobra.Command) string {
	s := []string{fmt.Sprintf("__fish_seen_subcommand_from %s", name)}
	cmd = cmd.Parent()

	for cmd.HasParent() {
		str := fmt.Sprintf("__fish_seen_subcommand_from %s", cmd.Name())
		s = append([]string{str}, s...)
		cmd = cmd.Parent()
	}

	return strings.Join(s, "; and ")
}

func completeCommand(buf *bytes.Buffer, cmd *cobra.Command) {
	names := strings.Split(cmd.NameAndAliases(), ", ")
	checks := make(map[string]string)

	if !cmd.HasFlags() && !cmd.HasSubCommands() {
		return
	}

	parentPath := buildParentPath(cmd.Name(), cmd)
	buf.WriteString(fmt.Sprintf("\n# Completions for the \"kubectl %s\" command\n", parentPath))

	for _, name := range names {
		checks[name] = buildParentCheck(name, cmd)
	}

	// localNonPersistentFlags := cmd.LocalNonPersistentFlags()

	cmd.NonInheritedFlags().VisitAll(func(flag *pflag.Flag) {
		if nonCompletableFlag(flag) {
			return
		}

		requiresArg := ""
		short := ""
		noFiles := "-f "

		if !flagIsBoolean(flag) {
			requiresArg = " -r"
		}

		if flag.Shorthand != "" {
			short = fmt.Sprintf(" -s %s", flag.Shorthand)
		}

		for key := range flag.Annotations {
			switch key {
			case cobra.BashCompFilenameExt:
				noFiles = ""
			}
		}

		if strings.HasPrefix(flag.Usage, "Path to") {
			noFiles = ""
		}

		if strings.HasSuffix(flag.Name, "-dir") {
			noFiles = ""
		}

		long := fmt.Sprintf(" -l %s", flag.Name)
		desc := fmt.Sprintf(" -d '%s'", strings.Replace(flag.Usage, "'", "\\'", -1))
		for _, name := range names {
			check := checks[name]
			buf.WriteString(fmt.Sprintf("complete -c kubectl %s-n '%s'%s%s%s%s\n", noFiles, check, requiresArg, short, long, desc))
		}
	})

	if cmd.HasSubCommands() {
		functionName, list := buildFishList(cmd)
		buf.WriteString(list)
		for _, name := range names {
			buf.WriteString(buildSubcommandCompletion(name, functionName))
		}
	}

	for _, sub := range cmd.Commands() {
		completeCommand(buf, sub)
	}
}

func printFlags(cmd *cobra.Command, indent int) {
	prefix := ""
	if indent != 0 {
		prefix = strings.Repeat(" ", indent)
	}

	fmt.Printf("%scommand: %s - %s\n", prefix, cmd.NameAndAliases(), cmd.Short)

	cmd.Flags().VisitAll(func(flag *pflag.Flag) {
		if flag.Shorthand != "" {
			fmt.Printf("%s  -> flag: -%s, --%s Description: \"%s\"\n", prefix, flag.Shorthand, flag.Name, flag.Usage)
		} else {
			fmt.Printf("%s  -> flag: --%s Description: \"%s\"\n", prefix, flag.Name, flag.Usage)
		}
		fmt.Printf("%s      -> %s\n", prefix, flag.NoOptDefVal)
	})

	if cmd.HasSubCommands() {
		for _, c := range cmd.Commands() {
			printFlags(c, indent+2)
		}
	}
}

func flagIsBoolean(flag *pflag.Flag) bool {
	return flag.Value.Type() == "bool"
}
