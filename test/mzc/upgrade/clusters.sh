export CHANNEL=stable-4.17
export MRR=release-41611-41703

sh signature.tmpl
sh cluster-version.tmpl
sh clusters-binding.tmpl
