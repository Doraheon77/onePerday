const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

export const api = {
  // 유저
  getUsers: (search?: string) =>
    fetch(`${BASE_URL}/admin/users?search=${search ?? ''}`).then(r => r.json()),

  deleteUser: (id: string) =>
    fetch(`${BASE_URL}/admin/users/${id}`, { method: 'DELETE' }).then(r => r.json()),

  // 영양제
  getSupplements: (keyword?: string, page?: number) =>
      fetch(`${BASE_URL}/admin/supplements?keyword=${keyword ?? ''}&page=${page ?? 1}`).then(r => r.json()),

  addSupplement: (data: any) =>
    fetch(`${BASE_URL}/admin/supplements`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(r => r.json()),

  deleteSupplement: (id: string) =>
    fetch(`${BASE_URL}/admin/supplements/${id}`, { method: 'DELETE' }).then(r => r.json()),

  getDashboard: () =>
    fetch(`${BASE_URL}/admin/dashboard`).then(r => r.json()),

  updateUser: (id: string, data: any) =>
    fetch(`${BASE_URL}/admin/users/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(r => r.json()),

  updateSupplement: (id: string, data: any) =>
    fetch(`${BASE_URL}/admin/supplements/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(r => r.json()),  
};