=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Need to add new YAML Front Matter variables, and update article generator code,
to allow for proper metadata creation for (Open Graph, FB) link sharing:

  https://meetedgar.com/blog/facebooks-new-link-previews-need-know-2018/

  https://developers.facebook.com/docs/sharing/webmasters

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Add new YAML Front Matter variables, for open graph/FB link sharing
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

    og:title - title for the link (if not set, use the existing "title" 
               variable)

    og:desc  - link sharing description (if not set, use the existing "abstract" 
               variable)

    og:image - Full URL to image to be displayed (if not set, use a defined 
               default image URL in settings.sh)

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Generate the following <meta/> tags in the article page (reference notes above)
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Using YAML "og:title" variable:

  <meta property="og:title" content="{title for link}" />

Use YAML "og:desc" variable:

  <meta property="og:description" content="{brief description}" />

Use YAML "og:image" variable:

  <meta property="og:image" content="{full URL to image}" />

Generate the following from the image file being used above:

  <meta property="og:image:width" content="{width}" />
  <meta property="og:image:height" content="{height}" />

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
To get the width and height of the image
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#!/bin/bash

# https://dummyimage.com/600x400
# ./testing.jpg

path=$1;
temp="$(basename $0)"-"$(echo $RANDOM | md5sum | head -c 16)";

# if the path is for a local image, do nothing
# otherwise, if it is a remote image, use curl
# to download it to a temporary image file
if [[ $path == http://* ]] || [[ $path == https://* ]]; then
  # curl image from URL to temporary image file
  curl -so $temp $path;

  # point path to temporary image file
  path=$temp;
fi

# use imagemagick to extract the width and height as a string
wh=`convert $path -ping -format '%w,%h' info: | cut -d , -f 1-2`;

# convert it to an array via string substitution
wha=(${wh//,/ });

# do something with the array elements
echo "width=${wha[0]}, height=${wha[1]}";

# remove the temporary image file if it exists
if [[ -f $temp ]]; then rm $temp; fi;

exit 1;