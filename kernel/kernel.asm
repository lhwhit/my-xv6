
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00001117          	auipc	sp,0x1
    80000004:	86813103          	ld	sp,-1944(sp) # 80000868 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00001617          	auipc	a2,0x1
    8000004e:	84660613          	addi	a2,a2,-1978 # 80000890 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00000797          	auipc	a5,0x0
    80000060:	71478793          	addi	a5,a5,1812 # 80000770 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <cpus+0xffffffff7fff566f>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00000797          	auipc	a5,0x0
    800000aa:	3bc78793          	addi	a5,a5,956 # 80000462 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consputc>:
// called by printf, and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    800000ec:	1141                	addi	sp,sp,-16
    800000ee:	e406                	sd	ra,8(sp)
    800000f0:	e022                	sd	s0,0(sp)
    800000f2:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    800000f4:	10000793          	li	a5,256
    800000f8:	00f50a63          	beq	a0,a5,8000010c <consputc+0x20>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    800000fc:	00000097          	auipc	ra,0x0
    80000100:	5ec080e7          	jalr	1516(ra) # 800006e8 <uartputc_sync>
  }
}
    80000104:	60a2                	ld	ra,8(sp)
    80000106:	6402                	ld	s0,0(sp)
    80000108:	0141                	addi	sp,sp,16
    8000010a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000010c:	4521                	li	a0,8
    8000010e:	00000097          	auipc	ra,0x0
    80000112:	5da080e7          	jalr	1498(ra) # 800006e8 <uartputc_sync>
    80000116:	02000513          	li	a0,32
    8000011a:	00000097          	auipc	ra,0x0
    8000011e:	5ce080e7          	jalr	1486(ra) # 800006e8 <uartputc_sync>
    80000122:	4521                	li	a0,8
    80000124:	00000097          	auipc	ra,0x0
    80000128:	5c4080e7          	jalr	1476(ra) # 800006e8 <uartputc_sync>
    8000012c:	bfe1                	j	80000104 <consputc+0x18>

000000008000012e <consoleinit>:
  uint e;  // Edit index
} cons;

void
consoleinit(void)
{
    8000012e:	1141                	addi	sp,sp,-16
    80000130:	e406                	sd	ra,8(sp)
    80000132:	e022                	sd	s0,0(sp)
    80000134:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000136:	00000597          	auipc	a1,0x0
    8000013a:	67a58593          	addi	a1,a1,1658 # 800007b0 <timervec+0x40>
    8000013e:	00009517          	auipc	a0,0x9
    80000142:	f5250513          	addi	a0,a0,-174 # 80009090 <cons>
    80000146:	00000097          	auipc	ra,0x0
    8000014a:	3c6080e7          	jalr	966(ra) # 8000050c <initlock>

  uartinit();
    8000014e:	00000097          	auipc	ra,0x0
    80000152:	54a080e7          	jalr	1354(ra) # 80000698 <uartinit>
  
}
    80000156:	60a2                	ld	ra,8(sp)
    80000158:	6402                	ld	s0,0(sp)
    8000015a:	0141                	addi	sp,sp,16
    8000015c:	8082                	ret

000000008000015e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000015e:	7179                	addi	sp,sp,-48
    80000160:	f406                	sd	ra,40(sp)
    80000162:	f022                	sd	s0,32(sp)
    80000164:	ec26                	sd	s1,24(sp)
    80000166:	e84a                	sd	s2,16(sp)
    80000168:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000016a:	c219                	beqz	a2,80000170 <printint+0x12>
    8000016c:	08054663          	bltz	a0,800001f8 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    80000170:	2501                	sext.w	a0,a0
    80000172:	4881                	li	a7,0
    80000174:	fd040693          	addi	a3,s0,-48

  i = 0;
    80000178:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    8000017a:	2581                	sext.w	a1,a1
    8000017c:	00000617          	auipc	a2,0x0
    80000180:	66460613          	addi	a2,a2,1636 # 800007e0 <digits>
    80000184:	883a                	mv	a6,a4
    80000186:	2705                	addiw	a4,a4,1
    80000188:	02b577bb          	remuw	a5,a0,a1
    8000018c:	1782                	slli	a5,a5,0x20
    8000018e:	9381                	srli	a5,a5,0x20
    80000190:	97b2                	add	a5,a5,a2
    80000192:	0007c783          	lbu	a5,0(a5) # 10000 <_entry-0x7fff0000>
    80000196:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    8000019a:	0005079b          	sext.w	a5,a0
    8000019e:	02b5553b          	divuw	a0,a0,a1
    800001a2:	0685                	addi	a3,a3,1
    800001a4:	feb7f0e3          	bgeu	a5,a1,80000184 <printint+0x26>

  if(sign)
    800001a8:	00088b63          	beqz	a7,800001be <printint+0x60>
    buf[i++] = '-';
    800001ac:	fe040793          	addi	a5,s0,-32
    800001b0:	973e                	add	a4,a4,a5
    800001b2:	02d00793          	li	a5,45
    800001b6:	fef70823          	sb	a5,-16(a4)
    800001ba:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800001be:	02e05763          	blez	a4,800001ec <printint+0x8e>
    800001c2:	fd040793          	addi	a5,s0,-48
    800001c6:	00e784b3          	add	s1,a5,a4
    800001ca:	fff78913          	addi	s2,a5,-1
    800001ce:	993a                	add	s2,s2,a4
    800001d0:	377d                	addiw	a4,a4,-1
    800001d2:	1702                	slli	a4,a4,0x20
    800001d4:	9301                	srli	a4,a4,0x20
    800001d6:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    800001da:	fff4c503          	lbu	a0,-1(s1)
    800001de:	00000097          	auipc	ra,0x0
    800001e2:	f0e080e7          	jalr	-242(ra) # 800000ec <consputc>
  while(--i >= 0)
    800001e6:	14fd                	addi	s1,s1,-1
    800001e8:	ff2499e3          	bne	s1,s2,800001da <printint+0x7c>
}
    800001ec:	70a2                	ld	ra,40(sp)
    800001ee:	7402                	ld	s0,32(sp)
    800001f0:	64e2                	ld	s1,24(sp)
    800001f2:	6942                	ld	s2,16(sp)
    800001f4:	6145                	addi	sp,sp,48
    800001f6:	8082                	ret
    x = -xx;
    800001f8:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    800001fc:	4885                	li	a7,1
    x = -xx;
    800001fe:	bf9d                	j	80000174 <printint+0x16>

0000000080000200 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000200:	1101                	addi	sp,sp,-32
    80000202:	ec06                	sd	ra,24(sp)
    80000204:	e822                	sd	s0,16(sp)
    80000206:	e426                	sd	s1,8(sp)
    80000208:	1000                	addi	s0,sp,32
    8000020a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000020c:	00009797          	auipc	a5,0x9
    80000210:	f407a223          	sw	zero,-188(a5) # 80009150 <pr+0x18>
  printf("panic: ");
    80000214:	00000517          	auipc	a0,0x0
    80000218:	5a450513          	addi	a0,a0,1444 # 800007b8 <timervec+0x48>
    8000021c:	00000097          	auipc	ra,0x0
    80000220:	02e080e7          	jalr	46(ra) # 8000024a <printf>
  printf(s);
    80000224:	8526                	mv	a0,s1
    80000226:	00000097          	auipc	ra,0x0
    8000022a:	024080e7          	jalr	36(ra) # 8000024a <printf>
  printf("\n");
    8000022e:	00000517          	auipc	a0,0x0
    80000232:	5f250513          	addi	a0,a0,1522 # 80000820 <digits+0x40>
    80000236:	00000097          	auipc	ra,0x0
    8000023a:	014080e7          	jalr	20(ra) # 8000024a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000023e:	4785                	li	a5,1
    80000240:	00000717          	auipc	a4,0x0
    80000244:	64f72023          	sw	a5,1600(a4) # 80000880 <panicked>
  for(;;)
    80000248:	a001                	j	80000248 <panic+0x48>

000000008000024a <printf>:
{
    8000024a:	7131                	addi	sp,sp,-192
    8000024c:	fc86                	sd	ra,120(sp)
    8000024e:	f8a2                	sd	s0,112(sp)
    80000250:	f4a6                	sd	s1,104(sp)
    80000252:	f0ca                	sd	s2,96(sp)
    80000254:	ecce                	sd	s3,88(sp)
    80000256:	e8d2                	sd	s4,80(sp)
    80000258:	e4d6                	sd	s5,72(sp)
    8000025a:	e0da                	sd	s6,64(sp)
    8000025c:	fc5e                	sd	s7,56(sp)
    8000025e:	f862                	sd	s8,48(sp)
    80000260:	f466                	sd	s9,40(sp)
    80000262:	f06a                	sd	s10,32(sp)
    80000264:	ec6e                	sd	s11,24(sp)
    80000266:	0100                	addi	s0,sp,128
    80000268:	8a2a                	mv	s4,a0
    8000026a:	e40c                	sd	a1,8(s0)
    8000026c:	e810                	sd	a2,16(s0)
    8000026e:	ec14                	sd	a3,24(s0)
    80000270:	f018                	sd	a4,32(s0)
    80000272:	f41c                	sd	a5,40(s0)
    80000274:	03043823          	sd	a6,48(s0)
    80000278:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000027c:	00009d97          	auipc	s11,0x9
    80000280:	ed4dad83          	lw	s11,-300(s11) # 80009150 <pr+0x18>
  if(locking)
    80000284:	020d9b63          	bnez	s11,800002ba <printf+0x70>
  if (fmt == 0)
    80000288:	040a0263          	beqz	s4,800002cc <printf+0x82>
  va_start(ap, fmt);
    8000028c:	00840793          	addi	a5,s0,8
    80000290:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000294:	000a4503          	lbu	a0,0(s4)
    80000298:	16050263          	beqz	a0,800003fc <printf+0x1b2>
    8000029c:	4481                	li	s1,0
    if(c != '%'){
    8000029e:	02500a93          	li	s5,37
    switch(c){
    800002a2:	07000b13          	li	s6,112
  consputc('x');
    800002a6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800002a8:	00000b97          	auipc	s7,0x0
    800002ac:	538b8b93          	addi	s7,s7,1336 # 800007e0 <digits>
    switch(c){
    800002b0:	07300c93          	li	s9,115
    800002b4:	06400c13          	li	s8,100
    800002b8:	a82d                	j	800002f2 <printf+0xa8>
    acquire(&pr.lock);
    800002ba:	00009517          	auipc	a0,0x9
    800002be:	e7e50513          	addi	a0,a0,-386 # 80009138 <pr>
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	2da080e7          	jalr	730(ra) # 8000059c <acquire>
    800002ca:	bf7d                	j	80000288 <printf+0x3e>
    panic("null fmt");
    800002cc:	00000517          	auipc	a0,0x0
    800002d0:	4fc50513          	addi	a0,a0,1276 # 800007c8 <timervec+0x58>
    800002d4:	00000097          	auipc	ra,0x0
    800002d8:	f2c080e7          	jalr	-212(ra) # 80000200 <panic>
      consputc(c);
    800002dc:	00000097          	auipc	ra,0x0
    800002e0:	e10080e7          	jalr	-496(ra) # 800000ec <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800002e4:	2485                	addiw	s1,s1,1
    800002e6:	009a07b3          	add	a5,s4,s1
    800002ea:	0007c503          	lbu	a0,0(a5)
    800002ee:	10050763          	beqz	a0,800003fc <printf+0x1b2>
    if(c != '%'){
    800002f2:	ff5515e3          	bne	a0,s5,800002dc <printf+0x92>
    c = fmt[++i] & 0xff;
    800002f6:	2485                	addiw	s1,s1,1
    800002f8:	009a07b3          	add	a5,s4,s1
    800002fc:	0007c783          	lbu	a5,0(a5)
    80000300:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000304:	cfe5                	beqz	a5,800003fc <printf+0x1b2>
    switch(c){
    80000306:	05678a63          	beq	a5,s6,8000035a <printf+0x110>
    8000030a:	02fb7663          	bgeu	s6,a5,80000336 <printf+0xec>
    8000030e:	09978963          	beq	a5,s9,800003a0 <printf+0x156>
    80000312:	07800713          	li	a4,120
    80000316:	0ce79863          	bne	a5,a4,800003e6 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000031a:	f8843783          	ld	a5,-120(s0)
    8000031e:	00878713          	addi	a4,a5,8
    80000322:	f8e43423          	sd	a4,-120(s0)
    80000326:	4605                	li	a2,1
    80000328:	85ea                	mv	a1,s10
    8000032a:	4388                	lw	a0,0(a5)
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	e32080e7          	jalr	-462(ra) # 8000015e <printint>
      break;
    80000334:	bf45                	j	800002e4 <printf+0x9a>
    switch(c){
    80000336:	0b578263          	beq	a5,s5,800003da <printf+0x190>
    8000033a:	0b879663          	bne	a5,s8,800003e6 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000033e:	f8843783          	ld	a5,-120(s0)
    80000342:	00878713          	addi	a4,a5,8
    80000346:	f8e43423          	sd	a4,-120(s0)
    8000034a:	4605                	li	a2,1
    8000034c:	45a9                	li	a1,10
    8000034e:	4388                	lw	a0,0(a5)
    80000350:	00000097          	auipc	ra,0x0
    80000354:	e0e080e7          	jalr	-498(ra) # 8000015e <printint>
      break;
    80000358:	b771                	j	800002e4 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000035a:	f8843783          	ld	a5,-120(s0)
    8000035e:	00878713          	addi	a4,a5,8
    80000362:	f8e43423          	sd	a4,-120(s0)
    80000366:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000036a:	03000513          	li	a0,48
    8000036e:	00000097          	auipc	ra,0x0
    80000372:	d7e080e7          	jalr	-642(ra) # 800000ec <consputc>
  consputc('x');
    80000376:	07800513          	li	a0,120
    8000037a:	00000097          	auipc	ra,0x0
    8000037e:	d72080e7          	jalr	-654(ra) # 800000ec <consputc>
    80000382:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000384:	03c9d793          	srli	a5,s3,0x3c
    80000388:	97de                	add	a5,a5,s7
    8000038a:	0007c503          	lbu	a0,0(a5)
    8000038e:	00000097          	auipc	ra,0x0
    80000392:	d5e080e7          	jalr	-674(ra) # 800000ec <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000396:	0992                	slli	s3,s3,0x4
    80000398:	397d                	addiw	s2,s2,-1
    8000039a:	fe0915e3          	bnez	s2,80000384 <printf+0x13a>
    8000039e:	b799                	j	800002e4 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800003a0:	f8843783          	ld	a5,-120(s0)
    800003a4:	00878713          	addi	a4,a5,8
    800003a8:	f8e43423          	sd	a4,-120(s0)
    800003ac:	0007b903          	ld	s2,0(a5)
    800003b0:	00090e63          	beqz	s2,800003cc <printf+0x182>
      for(; *s; s++)
    800003b4:	00094503          	lbu	a0,0(s2)
    800003b8:	d515                	beqz	a0,800002e4 <printf+0x9a>
        consputc(*s);
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	d32080e7          	jalr	-718(ra) # 800000ec <consputc>
      for(; *s; s++)
    800003c2:	0905                	addi	s2,s2,1
    800003c4:	00094503          	lbu	a0,0(s2)
    800003c8:	f96d                	bnez	a0,800003ba <printf+0x170>
    800003ca:	bf29                	j	800002e4 <printf+0x9a>
        s = "(null)";
    800003cc:	00000917          	auipc	s2,0x0
    800003d0:	3f490913          	addi	s2,s2,1012 # 800007c0 <timervec+0x50>
      for(; *s; s++)
    800003d4:	02800513          	li	a0,40
    800003d8:	b7cd                	j	800003ba <printf+0x170>
      consputc('%');
    800003da:	8556                	mv	a0,s5
    800003dc:	00000097          	auipc	ra,0x0
    800003e0:	d10080e7          	jalr	-752(ra) # 800000ec <consputc>
      break;
    800003e4:	b701                	j	800002e4 <printf+0x9a>
      consputc('%');
    800003e6:	8556                	mv	a0,s5
    800003e8:	00000097          	auipc	ra,0x0
    800003ec:	d04080e7          	jalr	-764(ra) # 800000ec <consputc>
      consputc(c);
    800003f0:	854a                	mv	a0,s2
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	cfa080e7          	jalr	-774(ra) # 800000ec <consputc>
      break;
    800003fa:	b5ed                	j	800002e4 <printf+0x9a>
  if(locking)
    800003fc:	020d9163          	bnez	s11,8000041e <printf+0x1d4>
}
    80000400:	70e6                	ld	ra,120(sp)
    80000402:	7446                	ld	s0,112(sp)
    80000404:	74a6                	ld	s1,104(sp)
    80000406:	7906                	ld	s2,96(sp)
    80000408:	69e6                	ld	s3,88(sp)
    8000040a:	6a46                	ld	s4,80(sp)
    8000040c:	6aa6                	ld	s5,72(sp)
    8000040e:	6b06                	ld	s6,64(sp)
    80000410:	7be2                	ld	s7,56(sp)
    80000412:	7c42                	ld	s8,48(sp)
    80000414:	7ca2                	ld	s9,40(sp)
    80000416:	7d02                	ld	s10,32(sp)
    80000418:	6de2                	ld	s11,24(sp)
    8000041a:	6129                	addi	sp,sp,192
    8000041c:	8082                	ret
    release(&pr.lock);
    8000041e:	00009517          	auipc	a0,0x9
    80000422:	d1a50513          	addi	a0,a0,-742 # 80009138 <pr>
    80000426:	00000097          	auipc	ra,0x0
    8000042a:	22a080e7          	jalr	554(ra) # 80000650 <release>
}
    8000042e:	bfc9                	j	80000400 <printf+0x1b6>

0000000080000430 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000430:	1101                	addi	sp,sp,-32
    80000432:	ec06                	sd	ra,24(sp)
    80000434:	e822                	sd	s0,16(sp)
    80000436:	e426                	sd	s1,8(sp)
    80000438:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000043a:	00009497          	auipc	s1,0x9
    8000043e:	cfe48493          	addi	s1,s1,-770 # 80009138 <pr>
    80000442:	00000597          	auipc	a1,0x0
    80000446:	39658593          	addi	a1,a1,918 # 800007d8 <timervec+0x68>
    8000044a:	8526                	mv	a0,s1
    8000044c:	00000097          	auipc	ra,0x0
    80000450:	0c0080e7          	jalr	192(ra) # 8000050c <initlock>
  pr.locking = 1;
    80000454:	4785                	li	a5,1
    80000456:	cc9c                	sw	a5,24(s1)
}
    80000458:	60e2                	ld	ra,24(sp)
    8000045a:	6442                	ld	s0,16(sp)
    8000045c:	64a2                	ld	s1,8(sp)
    8000045e:	6105                	addi	sp,sp,32
    80000460:	8082                	ret

0000000080000462 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	2ce080e7          	jalr	718(ra) # 80000738 <cpuid>
    printf("\n");
    __sync_synchronize();
    started = 1;
    printf("hart %d starting\n", cpuid());
  } else {
    while(started == 0)
    80000472:	00000717          	auipc	a4,0x0
    80000476:	41270713          	addi	a4,a4,1042 # 80000884 <started>
  if(cpuid() == 0){
    8000047a:	c505                	beqz	a0,800004a2 <main+0x40>
    while(started == 0)
    8000047c:	431c                	lw	a5,0(a4)
    8000047e:	2781                	sext.w	a5,a5
    80000480:	dff5                	beqz	a5,8000047c <main+0x1a>
      ;
    __sync_synchronize();
    80000482:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000486:	00000097          	auipc	ra,0x0
    8000048a:	2b2080e7          	jalr	690(ra) # 80000738 <cpuid>
    8000048e:	85aa                	mv	a1,a0
    80000490:	00000517          	auipc	a0,0x0
    80000494:	38050513          	addi	a0,a0,896 # 80000810 <digits+0x30>
    80000498:	00000097          	auipc	ra,0x0
    8000049c:	db2080e7          	jalr	-590(ra) # 8000024a <printf>
  }  
  while(1);        
    800004a0:	a001                	j	800004a0 <main+0x3e>
    consoleinit();
    800004a2:	00000097          	auipc	ra,0x0
    800004a6:	c8c080e7          	jalr	-884(ra) # 8000012e <consoleinit>
    printfinit();
    800004aa:	00000097          	auipc	ra,0x0
    800004ae:	f86080e7          	jalr	-122(ra) # 80000430 <printfinit>
    printf("\n");
    800004b2:	00000517          	auipc	a0,0x0
    800004b6:	36e50513          	addi	a0,a0,878 # 80000820 <digits+0x40>
    800004ba:	00000097          	auipc	ra,0x0
    800004be:	d90080e7          	jalr	-624(ra) # 8000024a <printf>
    printf("xv6 kernel is booting\n");
    800004c2:	00000517          	auipc	a0,0x0
    800004c6:	33650513          	addi	a0,a0,822 # 800007f8 <digits+0x18>
    800004ca:	00000097          	auipc	ra,0x0
    800004ce:	d80080e7          	jalr	-640(ra) # 8000024a <printf>
    printf("\n");
    800004d2:	00000517          	auipc	a0,0x0
    800004d6:	34e50513          	addi	a0,a0,846 # 80000820 <digits+0x40>
    800004da:	00000097          	auipc	ra,0x0
    800004de:	d70080e7          	jalr	-656(ra) # 8000024a <printf>
    __sync_synchronize();
    800004e2:	0ff0000f          	fence
    started = 1;
    800004e6:	4785                	li	a5,1
    800004e8:	00000717          	auipc	a4,0x0
    800004ec:	38f72e23          	sw	a5,924(a4) # 80000884 <started>
    printf("hart %d starting\n", cpuid());
    800004f0:	00000097          	auipc	ra,0x0
    800004f4:	248080e7          	jalr	584(ra) # 80000738 <cpuid>
    800004f8:	85aa                	mv	a1,a0
    800004fa:	00000517          	auipc	a0,0x0
    800004fe:	31650513          	addi	a0,a0,790 # 80000810 <digits+0x30>
    80000502:	00000097          	auipc	ra,0x0
    80000506:	d48080e7          	jalr	-696(ra) # 8000024a <printf>
    8000050a:	bf59                	j	800004a0 <main+0x3e>

000000008000050c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    8000050c:	1141                	addi	sp,sp,-16
    8000050e:	e422                	sd	s0,8(sp)
    80000510:	0800                	addi	s0,sp,16
  lk->name = name;
    80000512:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000514:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000518:	00053823          	sd	zero,16(a0)
}
    8000051c:	6422                	ld	s0,8(sp)
    8000051e:	0141                	addi	sp,sp,16
    80000520:	8082                	ret

0000000080000522 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000522:	411c                	lw	a5,0(a0)
    80000524:	e399                	bnez	a5,8000052a <holding+0x8>
    80000526:	4501                	li	a0,0
  return r;
}
    80000528:	8082                	ret
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000534:	6904                	ld	s1,16(a0)
    80000536:	00000097          	auipc	ra,0x0
    8000053a:	212080e7          	jalr	530(ra) # 80000748 <mycpu>
    8000053e:	40a48533          	sub	a0,s1,a0
    80000542:	00153513          	seqz	a0,a0
}
    80000546:	60e2                	ld	ra,24(sp)
    80000548:	6442                	ld	s0,16(sp)
    8000054a:	64a2                	ld	s1,8(sp)
    8000054c:	6105                	addi	sp,sp,32
    8000054e:	8082                	ret

0000000080000550 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000055a:	100024f3          	csrr	s1,sstatus
    8000055e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000562:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000564:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	1e0080e7          	jalr	480(ra) # 80000748 <mycpu>
    80000570:	5d3c                	lw	a5,120(a0)
    80000572:	cf89                	beqz	a5,8000058c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000574:	00000097          	auipc	ra,0x0
    80000578:	1d4080e7          	jalr	468(ra) # 80000748 <mycpu>
    8000057c:	5d3c                	lw	a5,120(a0)
    8000057e:	2785                	addiw	a5,a5,1
    80000580:	dd3c                	sw	a5,120(a0)
}
    80000582:	60e2                	ld	ra,24(sp)
    80000584:	6442                	ld	s0,16(sp)
    80000586:	64a2                	ld	s1,8(sp)
    80000588:	6105                	addi	sp,sp,32
    8000058a:	8082                	ret
    mycpu()->intena = old;
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	1bc080e7          	jalr	444(ra) # 80000748 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000594:	8085                	srli	s1,s1,0x1
    80000596:	8885                	andi	s1,s1,1
    80000598:	dd64                	sw	s1,124(a0)
    8000059a:	bfe9                	j	80000574 <push_off+0x24>

000000008000059c <acquire>:
{
    8000059c:	1101                	addi	sp,sp,-32
    8000059e:	ec06                	sd	ra,24(sp)
    800005a0:	e822                	sd	s0,16(sp)
    800005a2:	e426                	sd	s1,8(sp)
    800005a4:	1000                	addi	s0,sp,32
    800005a6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    800005a8:	00000097          	auipc	ra,0x0
    800005ac:	fa8080e7          	jalr	-88(ra) # 80000550 <push_off>
  if(holding(lk))
    800005b0:	8526                	mv	a0,s1
    800005b2:	00000097          	auipc	ra,0x0
    800005b6:	f70080e7          	jalr	-144(ra) # 80000522 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    800005ba:	4705                	li	a4,1
  if(holding(lk))
    800005bc:	e115                	bnez	a0,800005e0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    800005be:	87ba                	mv	a5,a4
    800005c0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    800005c4:	2781                	sext.w	a5,a5
    800005c6:	ffe5                	bnez	a5,800005be <acquire+0x22>
  __sync_synchronize();
    800005c8:	0ff0000f          	fence
  lk->cpu = mycpu();
    800005cc:	00000097          	auipc	ra,0x0
    800005d0:	17c080e7          	jalr	380(ra) # 80000748 <mycpu>
    800005d4:	e888                	sd	a0,16(s1)
}
    800005d6:	60e2                	ld	ra,24(sp)
    800005d8:	6442                	ld	s0,16(sp)
    800005da:	64a2                	ld	s1,8(sp)
    800005dc:	6105                	addi	sp,sp,32
    800005de:	8082                	ret
    panic("acquire");
    800005e0:	00000517          	auipc	a0,0x0
    800005e4:	24850513          	addi	a0,a0,584 # 80000828 <digits+0x48>
    800005e8:	00000097          	auipc	ra,0x0
    800005ec:	c18080e7          	jalr	-1000(ra) # 80000200 <panic>

00000000800005f0 <pop_off>:

void
pop_off(void)
{
    800005f0:	1141                	addi	sp,sp,-16
    800005f2:	e406                	sd	ra,8(sp)
    800005f4:	e022                	sd	s0,0(sp)
    800005f6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    800005f8:	00000097          	auipc	ra,0x0
    800005fc:	150080e7          	jalr	336(ra) # 80000748 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000600:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000604:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000606:	e78d                	bnez	a5,80000630 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000608:	5d3c                	lw	a5,120(a0)
    8000060a:	02f05b63          	blez	a5,80000640 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    8000060e:	37fd                	addiw	a5,a5,-1
    80000610:	0007871b          	sext.w	a4,a5
    80000614:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000616:	eb09                	bnez	a4,80000628 <pop_off+0x38>
    80000618:	5d7c                	lw	a5,124(a0)
    8000061a:	c799                	beqz	a5,80000628 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000061c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000620:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000624:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000628:	60a2                	ld	ra,8(sp)
    8000062a:	6402                	ld	s0,0(sp)
    8000062c:	0141                	addi	sp,sp,16
    8000062e:	8082                	ret
    panic("pop_off - interruptible");
    80000630:	00000517          	auipc	a0,0x0
    80000634:	20050513          	addi	a0,a0,512 # 80000830 <digits+0x50>
    80000638:	00000097          	auipc	ra,0x0
    8000063c:	bc8080e7          	jalr	-1080(ra) # 80000200 <panic>
    panic("pop_off");
    80000640:	00000517          	auipc	a0,0x0
    80000644:	20850513          	addi	a0,a0,520 # 80000848 <digits+0x68>
    80000648:	00000097          	auipc	ra,0x0
    8000064c:	bb8080e7          	jalr	-1096(ra) # 80000200 <panic>

0000000080000650 <release>:
{
    80000650:	1101                	addi	sp,sp,-32
    80000652:	ec06                	sd	ra,24(sp)
    80000654:	e822                	sd	s0,16(sp)
    80000656:	e426                	sd	s1,8(sp)
    80000658:	1000                	addi	s0,sp,32
    8000065a:	84aa                	mv	s1,a0
  if(!holding(lk))
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	ec6080e7          	jalr	-314(ra) # 80000522 <holding>
    80000664:	c115                	beqz	a0,80000688 <release+0x38>
  lk->cpu = 0;
    80000666:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    8000066a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    8000066e:	0f50000f          	fence	iorw,ow
    80000672:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000676:	00000097          	auipc	ra,0x0
    8000067a:	f7a080e7          	jalr	-134(ra) # 800005f0 <pop_off>
}
    8000067e:	60e2                	ld	ra,24(sp)
    80000680:	6442                	ld	s0,16(sp)
    80000682:	64a2                	ld	s1,8(sp)
    80000684:	6105                	addi	sp,sp,32
    80000686:	8082                	ret
    panic("release");
    80000688:	00000517          	auipc	a0,0x0
    8000068c:	1c850513          	addi	a0,a0,456 # 80000850 <digits+0x70>
    80000690:	00000097          	auipc	ra,0x0
    80000694:	b70080e7          	jalr	-1168(ra) # 80000200 <panic>

0000000080000698 <uartinit>:

extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000698:	1141                	addi	sp,sp,-16
    8000069a:	e406                	sd	ra,8(sp)
    8000069c:	e022                	sd	s0,0(sp)
    8000069e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800006a0:	100007b7          	lui	a5,0x10000
    800006a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800006a8:	f8000713          	li	a4,-128
    800006ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800006b0:	470d                	li	a4,3
    800006b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800006b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800006ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800006be:	469d                	li	a3,7
    800006c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800006c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800006c8:	00000597          	auipc	a1,0x0
    800006cc:	19058593          	addi	a1,a1,400 # 80000858 <digits+0x78>
    800006d0:	00009517          	auipc	a0,0x9
    800006d4:	a8850513          	addi	a0,a0,-1400 # 80009158 <uart_tx_lock>
    800006d8:	00000097          	auipc	ra,0x0
    800006dc:	e34080e7          	jalr	-460(ra) # 8000050c <initlock>
}
    800006e0:	60a2                	ld	ra,8(sp)
    800006e2:	6402                	ld	s0,0(sp)
    800006e4:	0141                	addi	sp,sp,16
    800006e6:	8082                	ret

00000000800006e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800006e8:	1101                	addi	sp,sp,-32
    800006ea:	ec06                	sd	ra,24(sp)
    800006ec:	e822                	sd	s0,16(sp)
    800006ee:	e426                	sd	s1,8(sp)
    800006f0:	1000                	addi	s0,sp,32
    800006f2:	84aa                	mv	s1,a0
  push_off();
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	e5c080e7          	jalr	-420(ra) # 80000550 <push_off>

  if(panicked){
    800006fc:	00000797          	auipc	a5,0x0
    80000700:	1847a783          	lw	a5,388(a5) # 80000880 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000704:	10000737          	lui	a4,0x10000
  if(panicked){
    80000708:	c391                	beqz	a5,8000070c <uartputc_sync+0x24>
    for(;;)
    8000070a:	a001                	j	8000070a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000070c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000710:	0ff7f793          	andi	a5,a5,255
    80000714:	0207f793          	andi	a5,a5,32
    80000718:	dbf5                	beqz	a5,8000070c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000071a:	0ff4f793          	andi	a5,s1,255
    8000071e:	10000737          	lui	a4,0x10000
    80000722:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	eca080e7          	jalr	-310(ra) # 800005f0 <pop_off>
}
    8000072e:	60e2                	ld	ra,24(sp)
    80000730:	6442                	ld	s0,16(sp)
    80000732:	64a2                	ld	s1,8(sp)
    80000734:	6105                	addi	sp,sp,32
    80000736:	8082                	ret

0000000080000738 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80000738:	1141                	addi	sp,sp,-16
    8000073a:	e422                	sd	s0,8(sp)
    8000073c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000073e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80000740:	2501                	sext.w	a0,a0
    80000742:	6422                	ld	s0,8(sp)
    80000744:	0141                	addi	sp,sp,16
    80000746:	8082                	ret

0000000080000748 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80000748:	1141                	addi	sp,sp,-16
    8000074a:	e422                	sd	s0,8(sp)
    8000074c:	0800                	addi	s0,sp,16
    8000074e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80000750:	2781                	sext.w	a5,a5
    80000752:	079e                	slli	a5,a5,0x7
  return c;
}
    80000754:	00009517          	auipc	a0,0x9
    80000758:	a3c50513          	addi	a0,a0,-1476 # 80009190 <cpus>
    8000075c:	953e                	add	a0,a0,a5
    8000075e:	6422                	ld	s0,8(sp)
    80000760:	0141                	addi	sp,sp,16
    80000762:	8082                	ret
	...

0000000080000770 <timervec>:
    80000770:	34051573          	csrrw	a0,mscratch,a0
    80000774:	e10c                	sd	a1,0(a0)
    80000776:	e510                	sd	a2,8(a0)
    80000778:	e914                	sd	a3,16(a0)
    8000077a:	710c                	ld	a1,32(a0)
    8000077c:	7510                	ld	a2,40(a0)
    8000077e:	6194                	ld	a3,0(a1)
    80000780:	96b2                	add	a3,a3,a2
    80000782:	e194                	sd	a3,0(a1)
    80000784:	4589                	li	a1,2
    80000786:	14459073          	csrw	sip,a1
    8000078a:	6914                	ld	a3,16(a0)
    8000078c:	6510                	ld	a2,8(a0)
    8000078e:	610c                	ld	a1,0(a0)
    80000790:	34051573          	csrrw	a0,mscratch,a0
    80000794:	30200073          	mret
	...
