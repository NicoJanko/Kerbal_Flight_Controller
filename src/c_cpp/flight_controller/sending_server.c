#include <arch/cc.h>
#include <lwip/ip_addr.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include <unistd.h>


#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#include <stdlib.h>
#endif

#define SERVER_PORT       8

#define REG_CTRL_WR_ADDR          XPAR_AXI_STATIC_REGISTER_0_BASEADDR
#define REG_ALTI_WR_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 4
#define REG_SPED_WR_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 8
#define REG_TPCH_WR_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 12
#define REG_HEAD_WR_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 16


volatile uint32_t* ctrl_reg = (volatile uint32_t*)(REG_CTRL_WR_ADDR);
volatile uint32_t* alti_reg = (volatile uint32_t*)(REG_ALTI_WR_ADDR);
volatile uint32_t* sped_reg = (volatile uint32_t*)(REG_SPED_WR_ADDR);
volatile uint32_t* tpch_reg = (volatile uint32_t*)(REG_TPCH_WR_ADDR);
volatile uint32_t* head_reg = (volatile uint32_t*)(REG_HEAD_WR_ADDR);

void send_data(const char *buffer){
    char *alti_ptr = strstr(buffer, "\"ALTI\"");
    float alti = 0.0;
    if (alti_ptr) {
        sscanf(alti_ptr, "\"ALTI\":%f", &alti);
        *alti_reg = alti;
    }
    char *sped_ptr = strstr(buffer, "\"SPED\"");
    float sped = 0.0;
    if (sped_ptr) {
        sscanf(sped_ptr, "\"SPED\":%f", &sped);
        *sped_reg = sped;
    }
    char *tpch_ptr = strstr(buffer, "\"TPCH\"");
    float tpch = 0.0;
    if (tpch_ptr) {
        sscanf(tpch_ptr, "\"TPCH\":%f", &tpch);
        *tpch_reg = tpch;
    }
    char *head_ptr = strstr(buffer, "\"HEAD\"");
    float head = 0.0;
    if (head_ptr) {
        sscanf(head_ptr, "\"HEAD\":%f", &head);
        *head_reg = head;
    }


};

void treat_command(const char *buffer){
        char command[32];
        int value = 0;

        char *cmd_ptr = strstr(buffer, "\"command\"");

        if (cmd_ptr) {
            sscanf(cmd_ptr, "\"command\": \"%31[^\"]\"", command);
        } else {
            printf("Invalid json received");
        }

        if (strcmp(command,"SET_CTRL" ) == 0) {
            char *val_ptr = strstr(buffer,"\"value\"");
            if (val_ptr) {
                int value = 0;
                sscanf(val_ptr,"\"value\": %d", &value);
                *ctrl_reg = value;
            } else {
                printf("invalid command structure");
            }
        }
        else if (strcmp(command,"SEND_DATA" ) == 0) {
                send_data(buffer);                
            }
        else {
                printf("Unknowned command");
            }
        };


static char json_buf[256];
static int json_len = 0;

static void process_incoming_json(const char *data, int len)
{
    for (int i = 0; i < len; i++) {
        char c = data[i];

        if (c == '\n') {
            // End of one JSON message
            json_buf[json_len] = 0;  // null-terminate

            printf("Received JSON: %s\n\r", json_buf);
            treat_command(json_buf);

            // Reset for next message
            json_len = 0;
        } else {
            if (json_len < sizeof(json_buf)-1) {
                json_buf[json_len++] = c;
            }
        }
    }
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{
	/* do not read the packet if we are not in ESTABLISHED state */
    (void)arg;
    (void)err;
	if (!p) {
		tcp_close(tpcb);
		tcp_recv(tpcb, NULL);
		return ERR_OK;
	}

	/* indicate that the packet has been received */
	tcp_recved(tpcb, p->len);

	/* echo back the payload */
	/* in this case, we assume that the payload is < TCP_SND_BUF */ 
    struct pbuf *q = p;
    while (q != NULL) {
        process_incoming_json((char*)q->payload, q->len);
        q = q->next;
    }
	/*if (tcp_sndbuf(tpcb) > p->len) {
		//err = tcp_write(tpcb, p->payload, p->len, 1);

        char buf[128];
        u16_t len = (p->len < sizeof(buf) - 1) ? p->len : sizeof(buf) - 1;
        memcpy(buf, p->payload, len);
        buf[len] = '\0';

        printf("Received command: %s\n\r", buf);
        char *cmd_ptr = strstr(buf, "\"command\"");
        if (cmd_ptr) {
            treat_command(buf);
        }

        
		


	} else
		xil_printf("no space in tcp_sndbuf\n\r");
    */

	// free the received pbuf
	pbuf_free(p);

	return ERR_OK;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;
    (void)arg;
    (void)err;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	return ERR_OK;
}

int start_sending_server(){
    struct tcp_pcb *pcb;
    err_t err;
    unsigned port = SERVER_PORT;

    //create new tcp pcb strucutre
    pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
    if(!pcb) {
        printf("Error creating PCB. Out of Memory\n\r");
        return -1;
    }
    //bind to a port
    err = tcp_bind(pcb, IP_ANY_TYPE,port);
    if (err != ERR_OK) {
        printf("Unable to bind to %d: err = %d\n\r",port,err);
        return -2;
    }

    //no argument to any callback functions
    tcp_arg(pcb,NULL);
    pcb = tcp_listen(pcb);
    if (!pcb) {
        printf("Out of Memory while listening\n\r");
        return -3;
    }
    tcp_accept(pcb,accept_callback);

    printf("TCP sending server started at port %d\n\r",port);
    return 0;



};
