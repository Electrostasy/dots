{ lib, ... }:

with lib;

let
  # Lookup-table for dec->hex values
  decLUT = listToAttrs (
    imap0 (idx: val: nameValuePair (toString idx) val) (
      genList (x: x) 10 ++ stringToCharacters "abcdef"
    )
  );

  # Lookup-table for hex->dec values
  hexLUT = mapAttrs'
    (name: value:
      nameValuePair (toString value) name
    )
    decLUT;

  # Convert a hex string of form "#ffffff" into an RGB list of values
  # with form "[ 255 255 255 ]"
  toRGB = hexStr:
    map
      (pair: foldr (a: b: a + b) 0 (imap0
        (i: e: (if isString e then toInt e else e) * (
          # Dirty hack because no power function
          if i == 0 then 1 else 16
        ))
        (reverseList (map (c: hexLUT.${toString c}) pair))
      ))
      (
        # Extracts red, green, blue components from hex string
        map
          (idx: sublist idx 2 (
            drop 1 (stringToCharacters hexStr)
          )
          ) [ 0 2 4 ]
      );

  # Convert an RGB list of values with form "[ 255 255 255 ]" to a hex string
  # with form "#ffffff"
  toHex = rgb:
    let
      recurse = n:
        # Abuse the fact there's no fraction in integer division
        let remainder = n - (n / 16) * 16;
        in
        if n == 0 then [ remainder ]
        else [ remainder (recurse (n / 16)) ];
    in
    pipe rgb [
      (map (color: reverseList (flatten (recurse color))))
      (map (value: if take 1 value == [ 0 ] then drop 1 value else value))
      (flatten)
      (map (value: decLUT.${toString value}))
      (foldl (a: b: (toString a) + (toString b)) "#")
    ];

  clamp = num:
    if num > 255 then 255 else
    if num < 0 then 0 else num;

  # A hacky method to round a float by converting the fraction to string
  round = real:
    let
      # We will occasionaly lose precision here but it doesn't really matter
      # in practice
      fraction = elemAt (splitString "." (toString real)) 1;
    in
    if fraction > "500000" then builtins.ceil real else builtins.floor real;
in
{
  utils = { inherit hexLUT decLUT toRGB toHex; };

  # TODO adjust as HSV instead of RGB
  # https://www.tutorialspoint.com/c-program-to-change-rgb-color-model-to-hsv-color-model
  # https://www.geeksforgeeks.org/program-change-rgb-color-model-hsv-color-model/
  lighten = hex: amount: toHex (
    map (c: clamp (c + round (amount * 2.55))) (toRGB hex)
  );

  darken = hex: amount: toHex (
    map (c: clamp (c - round (amount * 2.55))) (toRGB hex)
  );
}

