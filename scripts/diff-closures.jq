def filter: select(
	(.pname != null) and
	(.pname | endswith("-wrapper") | not)
);

# https://stackoverflow.com/a/70483232
def escape_regex:
	reduce ("\\\\", "\\*", "\\^", "\\?", "\\+", "\\.", "\\!", "\\{", "\\}", "\\[", "\\]", "\\$", "\\|", "\\(", "\\)") as $c (
		.;
		gsub($c; $c)
	);

def process_pkg($side):
	# The package name sometimes has other pre/suffixed strings not present
	# in the pname or version fields.
	{ ("-\(.version | escape_regex).*" as $version | .name | sub($version; "")): { ($side): .version } };

def ansi: {
	red: "\u001b[31m",
	green: "\u001b[32m",
	blue: "\u001b[34m",
	reset: "\u001b[0m"
};

def with_colour(colour):
	colour + . + ansi.reset;


([.[0].[].env] | map(filter | process_pkg("left"))) + ([.[1].[].env] | map(filter | process_pkg("right")))
| reduce .[] as $item ({}; . * $item)

# Print the results.
| to_entries
| reduce .[] as $item (
	{ added: [], removed: [], updated: [] };
	if $item.value.left == null and $item.value.right != null then
		.added += [ "\t\($item.key | with_colour(ansi.green)): \($item.value.right)" ]
	elif $item.value.left != null and $item.value.right == null then
		.removed += [ "\t\($item.key | with_colour(ansi.red)): \($item.value.left)" ]
	elif $item.value.left != $item.value.right then
		.updated += [ "\t\($item.key | with_colour(ansi.blue)): \($item.value.left) -> \($item.value.right)" ]
	end
)
| .added |= if length > 0 then [ "\(length) added packages:" ] + (. | sort) + [ "" ] else empty end
| .removed |= if length > 0 then [ "\(length) removed packages:" ] + (. | sort) + [ "" ] else empty end
| .updated |= if length > 0 then [ "\(length) version changes:" ] + (. | sort) + [ "" ] else empty end
| add
| .[0:-1]
| join("\n")
