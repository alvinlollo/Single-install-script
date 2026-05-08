function update --description 'Automatically finds binarys and uses update commands'
	if command -v pacman >/dev/null && command -v yay >/dev/null
		echo "✅ 'pacman' and 'yay' found. Updating."
		sudo pacman -Syu --noconfirm
		yay -Syu --sudoloop --save --answerclean None --answerdiff None --noconfirm
	else if command -v pacman >/dev/null
		echo "✅ 'pacman' found. Updating."
		sudo pacman -Syu --noconfirm
	end

	if command -v paru >/dev/null
		echo "✅ 'paru' found. Updating."
		paru -Syu
	end

	if command -v apt >/dev/null
		echo "✅ 'apt' found. Updating."
		sudo apt update && sudo apt full-upgrade -y
	end

	if command -v hyprpm >/dev/null
		echo "✅ 'hyprpm' found. Updating."
		hyprpm reload
		sleep 2
		hyprpm update
	end

	if command -v flatpak >/dev/null
		echo "✅ 'flatpak' found. Updating."
		flatpak update -y
	end

	if command -v npm >/dev/null
		echo "✅ 'npm' found. Updating."
		sudo npm install -g npm-check-updates
	end

	if command -v omz >/dev/null
		omz update
	end
end