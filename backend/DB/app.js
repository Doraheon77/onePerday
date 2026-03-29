const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function getSupplements() {
  // 1. 데이터가 너무 많으니 딱 3개만 가져오기 (take: 3)
  const top3Supplements = await prisma.supplements.findMany({
    take: 3, 
  });

  // 2. BigInt(n)의 'n'을 떼고 우리가 읽기 편한 글자로 변환해서 예쁘게 출력
  const cleanData = JSON.stringify(
    top3Supplements,
    (key, value) => (typeof value === 'bigint' ? value.toString() : value),
    2
  );

  console.log("💊 뽑아온 영양제 데이터 3개:");
  console.log(cleanData);
}

getSupplements();