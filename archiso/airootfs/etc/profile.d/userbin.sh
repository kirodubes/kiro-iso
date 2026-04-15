# /etc/profile.d/userbin.sh
if [ -d "$HOME/.bin" ]; then
  PATH="$HOME/.bin:$PATH"
fi

