'use client'
import { useEffect, useState } from 'react'
import { api } from '../../lib/api'

export default function SupplementsPage() {
  const [supplements, setSupplements] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(false)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [total, setTotal] = useState(0)

  const fetchSupplements = async (currentPage = page, keyword = search) => {
    setLoading(true)
    const res = await api.getSupplements(keyword, currentPage)
    setSupplements(res.data)
    setTotalPages(res.totalPages)
    setTotal(res.total)
    setLoading(false)
  }

  useEffect(() => {
    fetchSupplements()
  }, [])

  const handleSearch = () => {
    setPage(1)
    fetchSupplements(1, search)
  }

  const handlePageChange = (newPage: number) => {
    setPage(newPage)
    fetchSupplements(newPage, search)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('정말 삭제하시겠습니까?')) return
    await api.deleteSupplement(id)
    fetchSupplements(page, search)
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">영양제 관리</h1>
      {/* 검색 */}
      <div className="flex gap-2 mb-4">
        <input
          className="border p-2 flex-1 rounded"
          placeholder="영양제 검색"
          value={search}
          onChange={e => setSearch(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSearch()}
        />
        <button
          onClick={handleSearch}
          className="bg-blue-500 text-white px-4 py-2 rounded"
        >
          검색
        </button>
      </div>

      <p className="text-sm text-gray-500 mb-2">총 {total}개</p>

      {loading ? (
        <p>로딩 중...</p>
      ) : (
        <>
          <table className="w-full border-collapse border">
            <thead>
              <tr className="bg-gray-100">
                <th className="border p-2 text-left">영양제명</th>
                <th className="border p-2 text-left">성분</th>
                <th className="border p-2">삭제</th>
              </tr>
            </thead>
            <tbody>
              {supplements.map(s => (
                <tr key={s.id} className="border-t">
                  <td className="border p-2">{s.product_name}</td>
                  <td className="border p-2">{s.brand_name}</td>
                  <td className="border p-2 text-center">
                    <button
                      onClick={() => handleDelete(s.id)}
                      className="bg-red-500 text-white px-3 py-1 rounded"
                    >
                      삭제
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* 페이지네이션 */}
          <div className="flex justify-center gap-2 mt-4">
            <button
              onClick={() => handlePageChange(page - 1)}
              disabled={page === 1}
              className="px-3 py-1 border rounded disabled:opacity-40"
            >
              이전
            </button>
            {Array.from({ length: totalPages }, (_, i) => i + 1)
            .filter(p => p === 1 || p === totalPages || Math.abs(p - page) <= 2)
            .map((p, idx, arr) => (
                <div key={p} className="flex items-center gap-2">
                {idx > 0 && arr[idx - 1] !== p - 1 && (
                    <span className="px-2 py-1">...</span>
                )}
                <button
                    onClick={() => handlePageChange(p)}
                    className={`px-3 py-1 border rounded ${page === p ? 'bg-blue-500 text-white' : ''}`}
                >
                    {p}
                </button>
                </div>
            ))}
            <button
              onClick={() => handlePageChange(page + 1)}
              disabled={page === totalPages}
              className="px-3 py-1 border rounded disabled:opacity-40"
            >
              다음
            </button>
          </div>
        </>
      )}
    </div>
  )
}