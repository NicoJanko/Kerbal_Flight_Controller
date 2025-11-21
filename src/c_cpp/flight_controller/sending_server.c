#include <arch/cc.h>
#include <lwip/ip_addr.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include <unistd.h>
#include "reg_map_addr.h"


#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#include <stdlib.h>
#endif

#define SERVER_PORT       8




volatile uint32_t* ctrl_reg = (volatile uint32_t*)(REG_CTRL_WR_ADDR);
volatile uint32_t* alti_reg = (volatile uint32_t*)(REG_ALTI_WR_ADDR);
volatile uint32_t* sped_reg = (volatile uint32_t*)(REG_SPED_WR_ADDR);
volatile uint32_t* tpch_reg = (volatile uint32_t*)(REG_TPCH_WR_ADDR);
volatile uint32_t* head_reg = (volatile uint32_t*)(REG_HEAD_WR_ADDR);
uint32_t* iner_reg;
uint32_t* p_av_torq_reg;
uint32_t* r_av_torq_reg;
uint32_t* y_av_torq_reg;
volatile uint32_t* p_aveloc_reg = (volatile uint32_t*)(REG_PVLT_WR_ADDR);
volatile uint32_t* r_aveloc_reg = (volatile uint32_t*)(REG_RVLT_WR_ADDR);
volatile uint32_t* y_aveloc_reg = (volatile uint32_t*)(REG_YVLT_WR_ADDR);

void receive_data(const char *buffer){
    char *alti_ptr = strstr(buffer, "\"ALTI\"");
    float alti = 0.0;
    if (alti_ptr) {
        sscanf(alti_ptr, "\"ALTI\":%f", &alti);
        uint32_t alti_raw;
        memcpy(&alti_raw, &alti, 4);
        *alti_reg = alti_raw;
    }
    char *sped_ptr = strstr(buffer, "\"SPED\"");
    float sped = 0.0;
    if (sped_ptr) {
        sscanf(sped_ptr, "\"SPED\":%f", &sped);
        uint32_t sped_raw;
        memcpy(&sped_raw, &sped, 4);
        *sped_reg = sped_raw;
    }
    char *tpch_ptr = strstr(buffer, "\"TPCH\"");
    float tpch = 0.0;
    if (tpch_ptr) {
        sscanf(tpch_ptr, "\"TPCH\":%f", &tpch);
        uint32_t tpch_raw;
        memcpy(&tpch_raw, &tpch, 4);
        *tpch_reg = tpch_raw;
    }
    char *head_ptr = strstr(buffer, "\"HEAD\"");
    float head = 0.0;
    if (head_ptr) {
        sscanf(head_ptr, "\"HEAD\":%f", &head);
        uint32_t head_raw;
        memcpy(&head_raw, &head, 4);
        *head_reg = head_raw;
    }
    char *inertia_ptr = strstr(buffer, "\"INER\"");
    float inertia = 0.0;
    if (inertia_ptr) {
        sscanf(inertia_ptr, "\"INER\":%f", &head);
        uint32_t inertia_raw;
        memcpy(&inertia_raw, &head, 4);
        *head_reg = inertia_raw;
    }
    char *p_av_torq_ptr = strstr(buffer, "\"PVTQ\"");
    float p_av_torq = 0.0;
    if (p_av_torq_ptr) {
        sscanf(p_av_torq_ptr, "\"PVTQ\":%f", &p_av_torq);
        uint32_t p_av_torq_raw;
        memcpy(&p_av_torq_raw, &p_av_torq, 4);
        *p_av_torq_reg = p_av_torq_raw;
    }
    char *r_av_torq_ptr = strstr(buffer, "\"RVTQ\"");
    float r_av_torq = 0.0;
    if (r_av_torq_ptr) {
        sscanf(r_av_torq_ptr, "\"RVTQ\":%f", &r_av_torq);
        uint32_t r_av_torq_raw;
        memcpy(&r_av_torq_raw, &r_av_torq, 4);
        *r_av_torq_reg = r_av_torq_raw;
    }
    char *y_av_torq_ptr = strstr(buffer, "\"YVTQ\"");
    float y_av_torq = 0.0;
    if (y_av_torq_ptr) {
        sscanf(y_av_torq_ptr, "\"YVTQ\":%f", &y_av_torq);
        uint32_t y_av_torq_raw;
        memcpy(&y_av_torq_raw, &y_av_torq, 4);
        *y_av_torq_reg = y_av_torq_raw;
    }
    char *p_aveloc_ptr = strstr(buffer, "\"PVLT\"");
    float p_aveloc = 0.0;
    if (p_aveloc_ptr) {
        sscanf(p_aveloc_ptr, "\"PVTQ\":%f", &p_aveloc);
        uint32_t p_aveloc_raw;
        memcpy(&p_aveloc_raw, &p_aveloc, 4);
        *p_aveloc_reg = p_aveloc_raw;
    }
    char *p_aveloc_ptr = strstr(buffer, "\"PVLT\"");
    float p_aveloc = 0.0;
    if (p_aveloc_ptr) {
        sscanf(p_aveloc_ptr, "\"PVTQ\":%f", &p_aveloc);
        uint32_t p_aveloc_raw;
        memcpy(&p_aveloc_raw, &p_aveloc, 4);
        *p_aveloc_reg = p_aveloc_raw;
    }
    char *p_aveloc_ptr = strstr(buffer, "\"PVLT\"");
    float p_aveloc = 0.0;
    if (p_aveloc_ptr) {
        sscanf(p_aveloc_ptr, "\"PVTQ\":%f", &p_aveloc);
        uint32_t p_aveloc_raw;
        memcpy(&p_aveloc_raw, &p_aveloc, 4);
        *p_aveloc_reg = p_aveloc_raw;
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
                receive_data(buffer);                
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
