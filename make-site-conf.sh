#!/bin/bash

DOMAIN_DIR_NAME="Domäne-"
TEMPLEATE_FILE="site.conf.template"


PREFIX_LIST=( "FF-DO-" \
				"FF-DO-" \
				"FF-DO-" \
				"FF-DO-" \
				"FF-DO-" \
				"FF-DO-" \
				"FF-Werne-" \
				"FF-Luenen-" \
				"FF-Kamen-" \
				"FF-Unna-" \
				"FF-Schwerte-" )

SITE_NAME_LIST=( "Test und Dev" \
				"Außenbezirke" \
				"Dortmund 1" \
				"Dortmund 2" \
				"Dortmund 3" \
				"Dortmund 4" \
				"Werne" \
				"Lünen" \
				"Bergkamen, Kamen, Bönen" \
				"Unna" \
				"Schwerte, Holzwickede, Fröndenberg" )



while [ "$1" != '' ] ; do
  if [ $1 -le 0 ] ; then 
    echo bad number; min 1 is allowed
  else 
    if [ $1 -ge 17 ] ; then 
      echo bad number: max. 16 is allowd
    else 
      index=$(expr \( $1 - 1 \) )
      
      domain_prefix="FF-DO-"
      if [ $1 -le ${#PREFIX_LIST[*]} ] ; then 
        domain_prefix=${PREFIX_LIST[$index]}
      fi
      
      domain_name=""
      if [ $1 -le ${#SITE_NAME_LIST[*]} ] ; then 
        domain_name=$(printf ' - %s' "${SITE_NAME_LIST[$index]}")
      fi
      
      formated_index=$(printf '%02d' "$1")
      hex_val=$(printf '%02x' "$1")
      ip4net=$(printf '10.233.%02d' "$(expr 128 + 8 \* $index )")
      ip6net=$(printf '2a03:2260:300a:%04x' "$(expr 8192 + 256 \* $index )")

      /bin/sed \
		-e "s/%%DOMAIN_IP_NET4%%/$ip4net/g" \
		-e "s/%%DOMAIN_IP_NET6%%/$ip6net/g" \
		-e "s/%%DOMAIN_INDEX%%/$formated_index/g" \
		-e "s/%%DOMAIN_HEX_INDEX%%/$hex_val/g" \
		-e "s/%%DOMAIN_PREFIX%%/$domain_prefix/g" \
		-e "s/%%DOMAIN_NAME%%/$domain_name/g" \
		$TEMPLEATE_FILE
    fi
  fi
  shift
done

