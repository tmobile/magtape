package magtape

# This acts as an entrypoint to call all policies under "kubernetes.admission"

decisions[{"policy": p, "reasons": reasons}] {

  data.kubernetes.admission[p].matches
  reasons := data.kubernetes.admission[p].deny

}