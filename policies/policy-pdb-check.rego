package kubernetes.admission.policy_pdb

policy_metadata = {

	# Set MagTape Policy Info
	"name": "policy-pdb",
	"severity": "HIGH",
	"errcode": "MT1005",
	"targets": {"PodDisruptionBudget"},

}

servicetype = input.request.kind.kind

matches {

    # Verify request object type matches targets
    policy_metadata.targets[servicetype]
    
}

limits = {

	"minAvailable": [0, 66],
    "maxUnavailable": [33, 100],
	
}

# Generates a violation if the input doesn't specify a percentage (e.g., they used an absolute.)
deny[info] {

	# Get limit type
	limits[name]

    # Get limit value
	value := input.request.object.spec[name]

  	# Verify the value is a percentage
	[_, false] = get_percentage(value)

    msg := sprintf("[FAIL] %v - Value \"%v\" for \"%v\" should be a Percentage, not an Integer (%v)", [policy_metadata.severity, value, name, policy_metadata.errcode])

	info := {

    	"name": policy_metadata.name,
		"severity": policy_metadata.severity,
        "errcode": policy_metadata.errcode,
		"msg": msg,

    }

}

# Generates a violation if the input specifes a percentage out-of-range.
deny[info] {

    # Get limit range
	range := limits[name]

	# Get the percentage value
    [percent, true] = get_percentage(input.request.object.spec[name])

    # Verify the percentage is within range
	not within_range(percent, range)

    msg := sprintf("[FAIL] %v - Value (%v%%) for \"%v\" not within range %v%%-%v%% (%v)", [policy_metadata.severity, percent, name, range[0], range[1], policy_metadata.errcode])

	info := {

        "name": policy_metadata.name,
        "severity": policy_metadata.severity,
        "errcode": policy_metadata.errcode,
        "msg": msg,

    }

}

within_range(x, [_min, _max]) {

	x >= _min
    x <= _max

}

# get_percentage accepts a value and generates a tuple containing the 
# numeric percentage value and a boolean value indicating whether the
# input value could be converted to a numeric percentage.
#
# Examples:
#
#   get_percentage(50) == [0, false]
#   get_percentage("50") == [0, false]
#   get_percentage("50%") == [50, true]
get_percentage(value) = [0, false] {

	not is_string(value)

} else = [0, false] {

	not contains(value, "%")

} else = [percent, true] {

	percent := to_number(trim(value, "%"))

}