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

def fmt_name:
	# The package name sometimes has other pre/suffixed strings not present
	# in the pname or version fields.
	"-\(.version | escape_regex).*" as $version | .name | sub($version; "");

def by_side($side):
	{ (fmt_name): { ($side): .version } };

def ansi: {
	red: "\u001b[31m",
	green: "\u001b[32m",
	blue: "\u001b[34m",
	brred: "\u001b[91m",
	brgreen: "\u001b[92m",
	brblue: "\u001b[94m",
	reset: "\u001b[0m"
};

def with_colour(colour):
	colour + . + ansi.reset;


([.[2].[].env] | map(filter | fmt_name)) as $path |

([.[0].[].env] | map(filter | by_side("left"))) + ([.[1].[].env] | map(filter | by_side("right")))
| reduce .[] as $item ({}; . * $item)

# Print the results.
| to_entries
| reduce .[] as $item (
	{ added: [], removed: [], updated: [] };
	$item.key as $key |
	if $item.value.left == null and $item.value.right != null then
		.added += [ "\t\($key | with_colour(if $key | IN($path[]) then ansi.brgreen else ansi.green end)): \($item.value.right)" ]
	elif $item.value.left != null and $item.value.right == null then
		.removed += [ "\t\($key | with_colour(if $key | IN($path[]) then ansi.brred else ansi.red end)): \($item.value.left)" ]
	elif $item.value.left != $item.value.right then
		.updated += [ "\t\($key | with_colour(if $key | IN($path[]) then ansi.brblue else ansi.blue end)): \($item.value.left) -> \($item.value.right)" ]
	end
)
| .added |= if length > 0 then [ "\(length) added packages:" ] + (. | sort) + [ "" ] else empty end
| .removed |= if length > 0 then [ "\(length) removed packages:" ] + (. | sort) + [ "" ] else empty end
| .updated |= if length > 0 then [ "\(length) version changes:" ] + (. | sort) + [ "" ] else empty end
| add
| .[0:-1]
| join("\n")
