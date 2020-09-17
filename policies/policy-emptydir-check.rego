package kubernetes.admission.policy_emptydir

policy_metadata = {
	# Set MagTape Policy Info
	"name": "policy-emptydir",
	"severity": "MED",
	"errcode": "MT1009",
	"targets": {"Pod"},
}

kind = input.request.kind.kind

sizeLimit = 100

matches {
	# Verify request object type matches targets
	policy_metadata.targets[kind]
}

deny[info] {
	# Find volume spec
	volumes := input.request.object.spec.volumes
	exceed_err_msg := sprintf("is greater than %v Megabytes", [sizeLimit])

	# Checks emptydir configuration
	volume := volumes[_]
	name := volume.name
	emptydir_state := check_emptydir(volume, exceed_err_msg, sizeLimit)

	# Build message to return
	msg := sprintf("[FAIL] %v - Size limit of emptyDir volume \"%v\" %v (%v)", [policy_metadata.severity, name, emptydir_state, policy_metadata.errcode])

	info := {
		"name": policy_metadata.name,
		"severity": policy_metadata.severity,
		"errcode": policy_metadata.errcode,
		"msg": msg,
	}
}

# check_emptydir accepts three values (volume, exceed_err_msg, sizeLimit) 
# returns whether there the sizeLimit configuration for emptyDir is present, in megaBytes, and below the sizeLimit set above
check_emptydir(volume, exceed_err_msg, sizeLimit) = "is not set" {
	volume.emptyDir
	not volume.emptyDir.sizeLimit
} else = "is not in Megabytes" {
	volume.emptyDir.sizeLimit
	not endswith(trim_space(volume.emptyDir.sizeLimit), "M")
} else = exceed_err_msg {
	volume.emptyDir.sizeLimit
	limit := to_number(trim(trim_space(volume.emptyDir.sizeLimit), "M"))
	limit > sizeLimit
}
