typedef struct CompAC
{
  int arg
} CompAC;

CompAC  arr[1000000];

void iterate(int arg){
  for (int i = 999999;i>-1;i--){
    arr[i].arg += 1;
  }
}



