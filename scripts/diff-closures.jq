def filter_pname: select(
	# Packages that do not have a pname are not very interesting.
	(.pname != null) and
	# Likewise for wrapper packages.
	(.pname | endswith("-wrapper") | not)
);

# The package name sometimes has other pre/suffixed strings not present in the
# pname or version fields, so we escape the version string and remove it from
# the name instead of using a possibly incomplete pname.
def get_name_without_version:
	# https://stackoverflow.com/a/70483232
	(.version
	| reduce ("\\\\", "\\*", "\\^", "\\?", "\\+", "\\.", "\\!", "\\{", "\\}", "\\[", "\\]", "\\$", "\\|", "\\(", "\\)") as $c (
		.;
		gsub($c; $c)
	)) as $version |

	.name | sub("-\($version).*"; "");

# There may be packages with the same name but different versions present, so
# to avoid incorrect version comparisons due to overlapping package names, we
# split them by major version.
def group_versions_as($side): {
	(get_name_without_version): {
		(.version as $version | $version | split(".") | .[0]): {
			($side): .version
		}
	}
};

def ansi: {
	red: "\u001b[31m",
	green: "\u001b[32m",
	blue: "\u001b[34m",
	brred: "\u001b[91m",
	brgreen: "\u001b[92m",
	brblue: "\u001b[94m",
	_reset: "\u001b[0m"
};

# List of packages accessible from PATH.
([.[2].[].env] | map(filter_pname | get_name_without_version)) as $path |

# If a package is in our PATH, colour it with $path_colour, otherwise
# $regular_colour.
def with_colours($path_colour; $regular_colour):
	if IN($path[]) then
		$path_colour + . + ansi._reset
	else
		$regular_colour + . + ansi._reset
	end;


([.[0].[].env] | map(filter_pname | group_versions_as("left"))) + ([.[1].[].env] | map(filter_pname | group_versions_as("right")))
| reduce .[] as $item ({}; . * $item)

# NOTE: Handles major version changes assuming that there are only two packages
# changing major version in order to prevent a major version upgrade to look
# like a package removal and addition. This assumption may not always hold.
| . + map_values(
	map(.)
	| select((length == 2) and (.[0].left != null) and (.[0].right == null) and (.[1].left == null) and (.[1].right != null))
	| { (.[0].left[0:1]): { left: .[0].left, right: .[1].right } }
)

| map_values(
	map(
		# Each package name may have a number of different kinds of
		# updates for various different versions, so we group them here
		# for easier filtering.
		if .left == null and .right != null then
			{ type: "addition", string: .right }
		elif .left != null and .right == null then
			{ type: "removal", string: .left }
		elif .left != .right then
			{ type: "update", string: "\(.left) -> \(.right)" }
		else
			empty
		end
	)
	| select(length > 0)
	| {
		# Sort and join all the different package changes.
		additions: map(select(.type == "addition") | .string) | sort | join(", "),
		removals: map(select(.type == "removal") | .string) | sort | join(", "),
		updates: map(select(.type == "update") | .string) | sort | join(", ")
	}
)
| to_entries
| sort_by(.key)
| {
	# Group all the different package changes by category into the toplevel scope.
	additions: (
		map(
			select(.value.additions != "")
			| "\t\(.key | with_colours(ansi.brgreen; ansi.green)): \(.value.additions)"
		)
		| if length > 0 then [ "\(length) added packages:" ] + . + [ "" ] else empty end
	),
	removals: (
		map(
			select(.value.removals != "")
			| "\t\(.key | with_colours(ansi.brred; ansi.red)): \(.value.removals)"
		)
		| if length > 0 then [ "\(length) removed packages:" ] + . + [ "" ] else empty end
	),
	updates: (
		map(
			select(.value.updates != "")
			| "\t\(.key | with_colours(ansi.brblue; ansi.blue)): \(.value.updates)"
		)
		| if length > 0 then [ "\(length) updated packages:" ] + . + [ "" ] else empty end
	)
}
| add
| .[0:-1]
| join("\n")
