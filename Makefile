NUM_HOSTS = 2

%.yaml: %.jsonnet
	jsonnet --tla-code num_hosts=$(NUM_HOSTS) -o $@ $<

all: compose.yaml

clean:
	rm -f compose.yaml
