export class CheckIntakeDto {
  supplementIds: number[]; // 검사 대상 영양제 ID 배열 [cite: 20]
  age: number; // 사용자 나이
  gender: 'male' | 'female'; // 사용자 성별
}
