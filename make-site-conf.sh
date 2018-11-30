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
SITE_SEED_LIST=( "eb3dcef920c7ac9b3c8bba69a137fcf88ad5d4dc2f97ff1c2f9f1ab2bb944eb7" \
				"9bfb5d60aade652b8a1f7d7fa46c51b291dba4ef6ba03e5f46d8d4cef23ae00a" \
				"72d1940c9f77860ac1ca8b5778ab9e82e60194f80e35ff76033df2fa610efe3b" \
				"2941072831dc0e652118d9fe8ed20be1c8919d1711d4cc2896f8340c2ca51873" \
				"b87c485d1aba7790fb402ce9bb6e237c6cd42c7cdd8dfb7cfbe3a37ec0c843d4" \
				"2b575b88cb01d7ef137a8e12b0387d56f104d679c756bc9480ddfd1d055e135b" \
				"bb9eec48817c07905004de4284a700f16b9370773e143acce4dd241bbcd423d0" \
				"aa7fd7cbaee103d5d55845e9ff29f38fdfc115924b9a5e981097172b000390c6" \
				"a9c40bac755e5317724164738e822775097a34ee7a417fbd3aa544b391f03fa1" \
				"f60f42f60b7d489cedbfbe96ed11139712be51bd3748790d67504b2345dc022b" \
				"316326a5a4d1c84ee1807c99012151248f4fa41a6485d22f6932a190c56b4a4a" )



while [ "$1" != '' ] ; do
  if [ $1 -le 0 ] ; then 
    echo invalid domain number; min 1 is allowed
  else 
    if [ $1 -ge 255 ] ; then
      echo invalid domain number: max. 254 is allowed
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
      if [ $1 -le ${#SITE_SEED_LIST[*]} ] ; then 
        domain_seed=${SITE_SEED_LIST[$index]}
      fi
      
      formated_index=$(printf '%02d' "$1")
      hex_val=$(printf '%02x' "$1")
      ip4netbase=$(printf '10.%02d' $1)
      ip4net=$ip4netbase".0.0\/16"
      ip4adress="$ip4netbase.255.254"
      ip6netbase=$(printf '2a03:2260:300a:%04x' $1)
      ip6net=$ip6netbase"::\/64"
      ip6adress="$ip6netbase::ffd0"
      /bin/sed \
		-e "s/%%DOMAIN_IPV4_NET%%/$ip4net/g" \
		-e "s/%%DOMAIN_IPV4_ADR%%/$ip4adress/g" \
		-e "s/%%DOMAIN_IPV6_NET%%/$ip6net/g" \
		-e "s/%%DOMAIN_IPV6_ADR%%/$ip6adress/g" \
		-e "s/%%DOMAIN_INDEX%%/$formated_index/g" \
		-e "s/%%DOMAIN_HEX_INDEX%%/$hex_val/g" \
		-e "s/%%DOMAIN_PREFIX%%/$domain_prefix/g" \
		-e "s/%%DOMAIN_NAME%%/$domain_name/g" \
		-e "s/%%DOMAIN_SEED%%/$domain_seed/g" \
		$TEMPLEATE_FILE
    fi
  fi
  shift
done

