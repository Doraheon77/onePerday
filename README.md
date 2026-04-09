노션(Notion) README에 바로 복사해서 붙여넣기 좋도록, 가독성을 높이고 약간의 추가 정보(수정, 삭제 등)를 더해 완벽한 가이드 문서 형태로 다듬어 보았습니다. 노션의 '콜아웃'이나 '코드 블록' 기능과 찰떡같이 어울리는 마크다운 형식입니다.

🚀 Prisma x Supabase 데이터베이스 조작 가이드
이 문서는 Prisma Client를 사용하여 데이터베이스(Supabase)에 접근하고 데이터를 다루는(CRUD) 기본적인 방법을 안내합니다.

💡 참고: 아래 예제 코드에서는 supplements라는 영양제 테이블을 기준으로 작성되었습니다. 프로젝트 상황에 맞게 prisma.[테이블 이름] 부분을 수정하여 사용하세요.

⚙️ 0. 준비 작업 (Initialization)
데이터베이스와 통신하기 위해 가장 먼저 Prisma Client를 불러오고 실행해야 합니다. 데이터베이스 접근이 필요한 파일의 최상단에 작성해 주세요.

JavaScript
import { PrismaClient } from '@prisma/client';

// Prisma Client 인스턴스 생성
const prisma = new PrismaClient();
📝 1. 데이터 추가하기 (Create)
단일 데이터 추가 (create)
새로운 데이터 한 줄을 테이블에 추가할 때 사용합니다. id나 created_at 같이 데이터베이스에서 자동으로 생성되도록 설정된 값은 생략해도 됩니다.

JavaScript
async function addData() {
  const newSupplement = await prisma.supplements.create({
    data: {
      product_name: "얼라이브 멀티비타민",
      price: 15000,
      image_url: "https://example.com/image.jpg",
    },
  });
  
  console.log("✅ 데이터 추가 완료:", newSupplement);
}
여러 데이터 한 번에 추가 (createMany)
배열 형태로 여러 개의 데이터를 한 번에 밀어 넣을 때 사용합니다. 대량의 데이터를 초기화하거나 마이그레이션 할 때 유용합니다.

JavaScript
async function addMultipleData() {
  const newSupplements = await prisma.supplements.createMany({
    data: [
      { product_name: "비타민A", price: 10000 },
      { product_name: "비타민B", price: 12000 },
      { product_name: "비타민C", price: 8000 }
    ],
    skipDuplicates: true, // 🌟 꿀팁: 중복된 데이터가 있으면 에러를 띄우지 않고 자연스럽게 건너뜁니다.
  });
  
  console.log(`✅ ${newSupplements.count}개의 데이터가 추가되었습니다.`);
}
🔍 2. 데이터 가져오기 (Read)
테이블의 모든 데이터 가져오기 (findMany)
조건 없이 테이블에 있는 모든 데이터를 배열 형태로 가져옵니다.

JavaScript
async function getAllData() {
  const allSupplements = await prisma.supplements.findMany();
  console.log(allSupplements);
}
조건에 맞는 데이터만 필터링해서 가져오기 (where)
특정 조건을 만족하는 데이터만 골라서 가져옵니다.

JavaScript
async function getFilteredData() {
  const cheapSupplements = await prisma.supplements.findMany({
    where: {
      price: {
        lt: 20000, // lt(less than): 20,000원 '미만'인 조건
        // lte(이하), gt(초과), gte(이상) 등 다양한 연산자 사용 가능
      },
      image_url: null, // 이미지가 없는(null) 데이터만 조회
    },
  });
}
원하는 속성(컬럼)만 쏙쏙 뽑아오기 (select)
데이터베이스 용량과 네트워크 비용을 아끼기 위해, 전체 정보가 아닌 필요한 정보만 선택해서 가져올 수 있습니다.

JavaScript
async function getSpecificColumns() {
  const namesAndPrices = await prisma.supplements.findMany({
    select: {
      id: true,
      product_name: true,
      price: true,
      // true로 설정한 3가지 속성만 가져옵니다.
    },
  });
}
🛠️ 3. [추가] 데이터 수정 및 삭제하기 (Update & Delete)
완벽한 데이터 관리를 위해 수정과 삭제 방법도 함께 알아둡니다.

특정 데이터 수정하기 (update)
JavaScript
async function updateData() {
  const updatedSupplement = await prisma.supplements.update({
    where: {
      id: 1, // 수정할 데이터의 고유 ID
    },
    data: {
      price: 16000, // 변경할 값
    },
  });
}
특정 데이터 삭제하기 (delete)
JavaScript
async function deleteData() {
  const deletedSupplement = await prisma.supplements.delete({
    where: {
      id: 1, // 삭제할 데이터의 고유 ID
    },
  });
}
