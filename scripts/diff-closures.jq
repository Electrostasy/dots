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


([.[2].[].env] | map(filter | fmt_name)) as $path |

def with_colours($path_colour; $regular_colour):
	if IN($path[]) then
		$path_colour + . + ansi.reset
	else
		$regular_colour + . + ansi.reset
	end;


([.[0].[].env] | map(filter | by_side("left"))) + ([.[1].[].env] | map(filter | by_side("right")))
| reduce .[] as $item ({}; . * $item)

# Print the results.
| to_entries
| reduce .[] as $item (
	{ added: [], removed: [], updated: [] };
	if $item.value.left == null and $item.value.right != null then .added += [ $item ]
	elif $item.value.left != null and $item.value.right == null then .removed += [ $item ]
	elif $item.value.left != $item.value.right then .updated += [ $item ]
	end
)
| .added |=
	if length > 0 then
		[ "\(length) added packages:" ] +
		(sort_by(.key) | map("\t\(.key | with_colours(ansi.brgreen; ansi.green)): \(.value.right)")) +
		[ "" ]
	else
		empty
	end
| .removed |=
	if length > 0 then
		[ "\(length) removed packages:" ] +
		(sort_by(.key) | map("\t\(.key | with_colours(ansi.brred; ansi.red)): \(.value.left)")) +
		[ "" ]
	else
		empty
	end
| .updated |=
	if length > 0 then
		[ "\(length) updated packages:" ] +
		(sort_by(.key) | map("\t\(.key | with_colours(ansi.brblue; ansi.blue)): \(.value.left) -> \(.value.right)")) +
		[ "" ]
	else
		empty
	end
| add
| .[0:-1]
| join("\n")
