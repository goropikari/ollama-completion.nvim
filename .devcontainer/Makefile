.PHONY: setup
setup:
	sudo /usr/local/bin/init-firewall.sh
	echo 'eval "$$(direnv hook bash)"' >> ~/.bashrc
	curl -fsSL https://claude.ai/install.sh | bash

# OLLAMA_HOST=192.168.x.x
ollama:
	sudo iptables -I OUTPUT 1 -p tcp -d $${OLLAMA_HOST} --dport 11434 -j ACCEPT
