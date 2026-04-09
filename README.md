[README.md](https://github.com/user-attachments/files/26583535/README.md)
# 🗄️ Prisma × Supabase 데이터베이스 조작 가이드

> Prisma Client를 활용한 Supabase 데이터베이스 CRUD 완벽 정리

<br>

## 📌 목차

- [준비 작업](#-0-준비-작업-initialization)
- [데이터 추가하기](#-1-데이터-추가하기-create)
- [데이터 가져오기](#-2-데이터-가져오기-read)
- [데이터 수정 및 삭제하기](#️-3-데이터-수정-및-삭제하기-update--delete)

---

## ⚙️ 0. 준비 작업 (Initialization)

데이터베이스와 통신하기 위해 가장 먼저 **Prisma Client**를 불러오고 실행해야 합니다.  
데이터베이스 접근이 필요한 파일의 **최상단**에 작성해 주세요.

```js
import { PrismaClient } from '@prisma/client';

// Prisma Client 인스턴스 생성
const prisma = new PrismaClient();
```

<br>

---

## 📝 1. 데이터 추가하기 (Create)

### 단일 데이터 추가 — `create`

새로운 데이터 한 줄을 테이블에 추가할 때 사용합니다.  
`id`나 `created_at`처럼 DB에서 자동 생성되도록 설정된 값은 생략해도 됩니다.

```js
async function addData() {
  const newSupplement = await prisma.[테이블 이름].create({
    data: {
      product_name: "얼라이브 멀티비타민",
      price: 15000,
      image_url: "https://example.com/image.jpg",
    },
  });

  console.log("✅ 데이터 추가 완료:", newSupplement);
}
```

<br>

### 여러 데이터 한 번에 추가 — `createMany`

배열 형태로 여러 개의 데이터를 한 번에 밀어 넣을 때 사용합니다.  
대량의 데이터를 초기화하거나 마이그레이션할 때 유용합니다.

```js
async function addMultipleData() {
  const newSupplements = await prisma.[테이블 이름].createMany({
    data: [
      { product_name: "비타민A", price: 10000 },
      { product_name: "비타민B", price: 12000 },
      { product_name: "비타민C", price: 8000 },
    ],
    skipDuplicates: true, // 중복 데이터가 있으면 에러 없이 건너뜁니다
  });

  console.log(`✅ ${newSupplements.count}개의 데이터가 추가되었습니다.`);
}
```

> [!TIP]
> `skipDuplicates: true` 옵션을 사용하면 중복 데이터가 있어도 에러 없이 자연스럽게 건너뜁니다.

<br>

---

## 🔍 2. 데이터 가져오기 (Read)

### 모든 데이터 가져오기 — `findMany`

조건 없이 테이블에 있는 모든 데이터를 **배열** 형태로 가져옵니다.

```js
async function getAllData() {
  const allSupplements = await prisma.supplements.findMany();
  console.log(allSupplements);
}
```

<br>

### 조건 필터링 — `where`

특정 조건을 만족하는 데이터만 골라서 가져옵니다.

```js
async function getFilteredData() {
  const cheapSupplements = await prisma.supplements.findMany({
    where: {
      price: {
        lt: 20000,  // lt  : 미만 (less than)
                    // lte : 이하 (less than or equal)
                    // gt  : 초과 (greater than)
                    // gte : 이상 (greater than or equal)
      },
      image_url: null, // 이미지가 없는(null) 데이터만 조회
    },
  });
}
```

| 연산자 | 의미 | 예시 |
|:------:|:----:|:----:|
| `lt`  | 미만 | `price < 20000` |
| `lte` | 이하 | `price <= 20000` |
| `gt`  | 초과 | `price > 20000` |
| `gte` | 이상 | `price >= 20000` |

<br>

### 원하는 컬럼만 선택 — `select`

필요한 정보만 선택해서 가져와 **데이터 용량과 네트워크 비용**을 절약할 수 있습니다.

```js
async function getSpecificColumns() {
  const namesAndPrices = await prisma.supplements.findMany({
    select: {
      id: true,
      product_name: true,
      price: true,
      // true로 설정한 컬럼만 가져옵니다
    },
  });
}
```

<br>

---

## 🛠️ 3. 데이터 수정 및 삭제하기 (Update & Delete)

### 특정 데이터 수정 — `update`

`where` 조건으로 대상을 특정하고, `data`에 변경할 값을 입력합니다.

```js
async function updateData() {
  const updatedSupplement = await prisma.supplements.update({
    where: {
      id: 1,         // 수정할 데이터의 고유 ID
    },
    data: {
      price: 16000,  // 변경할 값
    },
  });
}
```

<br>

### 특정 데이터 삭제 — `delete`

`where` 조건에 해당하는 데이터를 테이블에서 삭제합니다.

```js
async function deleteData() {
  const deletedSupplement = await prisma.supplements.delete({
    where: {
      id: 1, // 삭제할 데이터의 고유 ID
    },
  });
}
```

> [!WARNING]
> `delete`는 되돌릴 수 없습니다. `where` 조건을 꼭 확인한 후 실행하세요.

<br>

---

## 📋 메서드 한눈에 보기

| 작업 | 메서드 | 설명 |
|:----:|:------:|:-----|
| **Create** | `create` | 단일 데이터 추가 |
| **Create** | `createMany` | 다중 데이터 한 번에 추가 |
| **Read** | `findMany` | 전체 또는 조건부 데이터 조회 |
| **Read** | `findUnique` | 고유값 기준 단일 데이터 조회 |
| **Update** | `update` | 특정 데이터 수정 |
| **Delete** | `delete` | 특정 데이터 삭제 |

<br>

---

<div align="center">

**🔗 참고 링크**

[![Prisma Docs](https://img.shields.io/badge/Prisma-Docs-2D3748?style=for-the-badge&logo=prisma&logoColor=white)](https://www.prisma.io/docs)
[![Supabase Docs](https://img.shields.io/badge/Supabase-Docs-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/docs)

</div>
