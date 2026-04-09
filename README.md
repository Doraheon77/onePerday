#Prisma 사용법

#0 준비
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

#1 데이터 추가하기
- 단일 데이터
async function addData() {
  const newSupplement = await prisma.[테이블 이름].create({
    data: {
      product_name: "얼라이브 멀티비타민",
      price: 15000,
      image_url: "https://example.com/image.jpg",
    },
  });
  
  console.log("추가된 데이터:", newSupplement);
  }

  - 여러 데이터
  async function addMultipleData() {
  const newSupplements = await prisma.[테이블 이름].createMany({
    data: [
      { product_name: "비타민A", price: 10000 },
      { product_name: "비타민B", price: 12000 },
      { product_name: "비타민C", price: 8000 }
    ],
    skipDuplicates: true, // 중복된 데이터가 있으면 에러 없이 건너뛰는 유용한 옵션입니다.
  });

#2 데이터 가져오기
- 모든 데이터 가져오기
async function getAllData() {  
  const allSupplements = await prisma.[테이블 이름].findMany();
  console.log(allSupplements);
}
- 조건에 맞는 데이터 가져오기
async function getFilteredData() {
  const cheapSupplements = await prisma.supplements.findMany({
    where: {
      price: {
        lt: 20000, // lt(less than): 20,000원 '미만'인 데이터만 가져옵니다.
      },
      image_url: null, // 이미지가 없는 데이터만 가져옵니다.
    },
  });
}
- 원하는 속성만 가져오기
async function getSpecificColumns() {
  const namesAndPrices = await prisma.supplements.findMany({
    select: {
      id: true,
      product_name: true,
      price: true,
      // true로 설정한 3가지만 쏙 뽑아옵니다.
    },
  });
}

