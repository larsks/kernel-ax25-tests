#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include <netax25/ax25.h>
#include <netax25/axconfig.h>
#include <netax25/axlib.h>

#define OPT_MSG 'm'
#define OPTSTRING "m:"

char *msg = "HELLO AX.25 CALLER\r\n";

int main(int argc, char *argv[]) {
  int ch, sock;
  socklen_t addrlen;
  char *port = NULL, *addr = NULL;
  struct full_sockaddr_ax25 sockaddr;

  addrlen = sizeof(struct full_sockaddr_ax25);

  while ((ch = getopt(argc, argv, OPTSTRING)) != -1) {
    switch (ch) {
    case OPT_MSG:
      msg = strdup(optarg);
      break;
    default:
      fprintf(stderr, "unhandled option: %c\n", ch);
      exit(2);
      break;
    }
  }

  if (argc != 2) {
    fprintf(stderr, "you must provide an ax.25 port name\n");
    exit(2);
  }

  if (ax25_config_load_ports() == 0) {
    fprintf(stderr, "ax25d: no AX.25 port data configured\n");
    return 1;
  }

  port = argv[1];
  if ((addr = ax25_config_get_addr(port)) == NULL) {
    fprintf(stderr, "%s: invalid ax.25 port name\n", port);
    exit(1);
  }
  fprintf(stderr, "port %s -> addr %s\n", port, addr);

  sockaddr.fsa_ax25.sax25_family = AF_AX25;
  sockaddr.fsa_ax25.sax25_ndigis = 0;
  ax25_aton_entry(addr, sockaddr.fsa_ax25.sax25_call.ax25_call);

  if ((sock = socket(AF_AX25, SOCK_SEQPACKET, 0)) < 0) {
    perror("socket");
    return 1;
  }

  if (bind(sock, (struct sockaddr *)&sockaddr, addrlen) < 0) {
    perror("bind");
    return 1;
  }

  if (listen(sock, SOMAXCONN) < 0) {
    perror("listen");
    return 1;
  }

  while (1) {
    struct full_sockaddr_ax25 clientaddr;
    socklen_t clientlen;
    int new;
    char buf[1];

    if ((new = accept(sock, (struct sockaddr *)&clientaddr, &clientlen)) < 0) {
      perror("accept");
      exit(1);
    }

    fprintf(stderr, "accepted connection from %s\n",
            ax25_ntoa(&clientaddr.fsa_ax25.sax25_call));
    write(new, msg, strlen(msg));
    sleep(1);
    fprintf(stderr, "disconnecting.\n");
    close(new);
  }
}
