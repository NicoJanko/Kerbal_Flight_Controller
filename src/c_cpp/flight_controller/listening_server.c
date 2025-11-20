//This module is used to send data to a pc via eth0

#include <arch/cc.h>
#include <lwip/ip_addr.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xil_io.h"


#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#include <stdlib.h>
#endif

#define SERVER_PORT       7

#define BASE_ADDR          XPAR_AXI_STATIC_REGISTER_0_BASEADDR
#define REG_THRT_R_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 0x0080
#define REG_CPCH_R_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 0x0084
#define REG_ROLL_R_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 0x0088
#define REG_CYAW_R_ADDR            XPAR_AXI_STATIC_REGISTER_0_BASEADDR + 0x008C


//volatile uint32_t* count_reg = (volatile uint32_t*)(REG_0_R_ADDR);
//volatile uint32_t* freq_reg = (volatile uint32_t*)(REG_1_WR_ADDR);

static struct tcp_pcb *pcb_client = NULL;

//err_t recv_callback(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err){
    // closing or loosing connection
    //if (!p) {
        //tcp_close(tpcb);
        //tcp_recv(tpcb,NULL);
        //return ERR_OK;
    //}
    //tcp_recved(tpcb,p->len);

    //if (tcp_sndbuf(tpcb) > p->len) {
        // here you write the behavior 
        //tcp_write(tpcb, my_data_buffer, my_data_length, TCP_WRITE_FLAG_COPY);
        //printf("Connection receveid");
    //} else {
        //printf("no spavce in tcp_sndbuff");
    //}
    //pbuf_free(p);

    //return ERR_OK;
//};

//called when the client connect
static err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err) {
    //static int connection = 1;
    (void)arg;
    (void)err;
    printf("Client connected on port 7\n\r");
    pcb_client = newpcb;
    // set the receive call back for this connection
    //tcp_recv(newpcb, recv_callback);
    // set the connection id for this connection
    //tcp_arg(newpcb, (void*)(UINTPTR)connection);

    // increment futur connection id
    //connection++;

    return ERR_OK;
};

//start the tcp server
int start_listening_server(){
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

    printf("TCP listening server started at port %d\n\r",port);
    return 0;



};

int transfer_data() {
    if (pcb_client == NULL) return 0;   // no client connected yet

    //uint32_t val = *count_reg;
    uint32_t thrt = Xil_In32(REG_THRT_R_ADDR);
    uint32_t cpch = Xil_In32(REG_CPCH_R_ADDR);
    uint32_t roll = Xil_In32(REG_ROLL_R_ADDR);
    uint32_t cyaw = Xil_In32(REG_CYAW_R_ADDR);
    //uint32_t freq = *freq_reg;
    //printf("freq = %d, count = %d\n\r",freq, val);
    char msg[256];
    int len = sprintf(msg, "{\"control\" : {\"thrt\": %f, \"cpch\": %f, \"roll\": %f, \"cyaw\": %f}}\n", (float)thrt,(float)cpch,(float)roll,(float)cyaw);

    if (tcp_sndbuf(pcb_client) >= len) {
        tcp_write(pcb_client, msg, len, TCP_WRITE_FLAG_COPY);
        tcp_output(pcb_client); // push immediately
        //printf(msg);
        usleep(400);
    }

    return 0;
}

