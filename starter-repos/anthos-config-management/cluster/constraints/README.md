# Constraints with Policy Controller

You can place constraint templates and constraints that you want to be
applied everywhere in this directory.

For example, if you want to enforce the presence of a "team" label on
Namespace objects, place the following content in a file:

```
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-geo
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels:
      - key: "team"
```

See the [Policy Controller](https://cloud.google.com/anthos-config-management/docs/how-to/creating-constraints-and-templates)
documentation for more information.