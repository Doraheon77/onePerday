'use client'
import { useEffect, useState } from 'react'
import { api } from '../../lib/api'

const inputStyle = {
  width: '100%', padding: '9px 12px', border: '1.5px solid #c8e6c9',
  borderRadius: '8px', fontSize: '14px', outline: 'none', backgroundColor: 'white',
}

const labelStyle = {
  fontSize: '13px', fontWeight: 600, color: '#2d8a5e', marginBottom: '4px', display: 'block' as const,
}

const fields = [
  { key: 'product_name', label: '영양제명 *' },
  { key: 'category', label: '카테고리' },
  { key: 'brand_name', label: '브랜드명' },
  { key: 'reference_amount', label: '기준량' },
  { key: 'serving_size', label: '1회 제공량 (숫자)' },
  { key: 'serving_unit', label: '단위' },
  { key: 'serving_weight', label: '1회 중량' },
  { key: 'daily_servings', label: '1일 섭취 횟수' },
  { key: 'total_weight', label: '총 중량' },
  { key: 'manufacturer', label: '제조사' },
  { key: 'origin', label: '원산지' },
  { key: 'image_url', label: '이미지 URL' },
  { key: 'shop_url', label: '쇼핑 URL' },
  { key: 'price', label: '가격 (숫자)' },
]

const emptyForm = {
  product_name: '', category: '', brand_name: '', reference_amount: '',
  serving_size: '', serving_unit: '', serving_weight: '', daily_servings: '',
  total_weight: '', manufacturer: '', origin: '', image_url: '', shop_url: '', price: '',
}

export default function SupplementsPage() {
  const [supplements, setSupplements] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(false)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [showAddModal, setShowAddModal] = useState(false)
  const [editSupp, setEditSupp] = useState<any>(null)
  const [form, setForm] = useState(emptyForm)

  const fetchSupplements = async (currentPage = page, keyword = search) => {
    setLoading(true)
    const res = await api.getSupplements(keyword, currentPage)
    setSupplements(res.data)
    setTotalPages(res.totalPages)
    setLoading(false)
  }

  useEffect(() => { fetchSupplements() }, [])

  const handleSearch = () => { setPage(1); fetchSupplements(1, search) }
  const handlePageChange = (newPage: number) => { setPage(newPage); fetchSupplements(newPage, search) }

  const handleDelete = async (id: string) => {
    if (!confirm('정말 삭제하시겠습니까?')) return
    await api.deleteSupplement(id)
    fetchSupplements(page, search)
  }

  const handleAdd = async () => {
    if (!form.product_name.trim()) return alert('영양제 이름은 필수입니다.')
    await api.addSupplement({
      ...form,
      serving_size: form.serving_size ? parseFloat(form.serving_size) : null,
      price: form.price ? parseInt(form.price) : null,
    })
    setShowAddModal(false)
    setForm(emptyForm)
    fetchSupplements(1, search)
  }

  const handleUpdate = async () => {
    if (!editSupp.product_name?.trim()) return alert('영양제 이름은 필수입니다.')
    await api.updateSupplement(editSupp.id, {
      ...editSupp,
      serving_size: editSupp.serving_size ? parseFloat(editSupp.serving_size) : null,
      price: editSupp.price ? parseInt(editSupp.price) : null,
    })
    setEditSupp(null)
    fetchSupplements(page, search)
  }

  const btnStyle = (color: string, bg: string, border: string) => ({
    backgroundColor: bg, color, border: `1px solid ${border}`,
    borderRadius: '8px', padding: '6px 14px', fontSize: '13px',
    cursor: 'pointer', fontWeight: 600,
  })

  const ModalContent = ({ data, setData, onConfirm, onClose, title }: any) => (
    <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
      <div style={{ backgroundColor: 'white', borderRadius: '16px', padding: '2rem', width: '560px', maxHeight: '80vh', overflowY: 'auto', boxShadow: '0 8px 32px rgba(0,0,0,0.15)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <h2 style={{ fontSize: '18px', fontWeight: 700, color: '#2d8a5e' }}>{title}</h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#888' }}>✕</button>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
          {fields.map(f => (
            <div key={f.key} style={{ gridColumn: f.key === 'image_url' || f.key === 'shop_url' ? 'span 2' : 'span 1' }}>
              <label style={labelStyle}>{f.label}</label>
              <input
                style={inputStyle}
                value={data[f.key] ?? ''}
                onChange={e => setData({ ...data, [f.key]: e.target.value })}
                placeholder={f.label.replace(' *', '')}
              />
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', gap: '8px', marginTop: '1.5rem', justifyContent: 'flex-end' }}>
          <button onClick={onClose} style={{ padding: '10px 20px', borderRadius: '10px', border: '1.5px solid #c8e6c9', backgroundColor: 'white', color: '#2d8a5e', cursor: 'pointer', fontWeight: 600 }}>취소</button>
          <button onClick={onConfirm} style={{ padding: '10px 20px', borderRadius: '10px', border: 'none', backgroundColor: '#2d8a5e', color: 'white', cursor: 'pointer', fontWeight: 600 }}>저장</button>
        </div>
      </div>
    </div>
  )

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1 style={{ fontSize: '22px', fontWeight: 700, color: '#2d8a5e' }}>영양제 관리</h1>
        <button
          onClick={() => { setForm(emptyForm); setShowAddModal(true) }}
          style={{ backgroundColor: '#2d8a5e', color: 'white', border: 'none', borderRadius: '10px', padding: '10px 20px', fontSize: '15px', cursor: 'pointer', fontWeight: 600 }}
        >
          + 영양제 추가
        </button>
      </div>

      <div style={{ display: 'flex', gap: '8px', marginBottom: '1rem' }}>
        <input
          style={{ flex: 1, padding: '10px 14px', border: '1.5px solid #c8e6c9', borderRadius: '10px', fontSize: '15px', outline: 'none', backgroundColor: 'white' }}
          placeholder="영양제 검색"
          value={search}
          onChange={e => setSearch(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSearch()}
        />
        <button onClick={handleSearch} style={{ backgroundColor: '#2d8a5e', color: 'white', border: 'none', borderRadius: '10px', padding: '10px 20px', fontSize: '15px', cursor: 'pointer', fontWeight: 600 }}>검색</button>
      </div>

      {loading ? (
        <p style={{ color: '#2d8a5e', textAlign: 'center', padding: '2rem' }}>로딩 중...</p>
      ) : (
        <>
          <div style={{ backgroundColor: 'white', borderRadius: '14px', border: '1.5px solid #c8e6c9', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ backgroundColor: '#e8f5e9' }}>
                  {['영양제명', '제조사', ''].map(h => (
                    <th key={h} style={{ padding: '12px 16px', textAlign: 'left', fontSize: '13px', fontWeight: 600, color: '#2d8a5e' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {supplements.map((s, i) => (
                  <tr key={s.id} style={{ borderTop: '1px solid #f0f0f0', backgroundColor: i % 2 === 0 ? 'white' : '#fafff8' }}>
                    <td style={{ padding: '12px 16px', fontSize: '14px' }}>{s.product_name}</td>
                    <td style={{ padding: '12px 16px', fontSize: '14px', color: '#555' }}>{s.manufacturer ?? '-'}</td>
                    <td style={{ padding: '12px 16px', display: 'flex', gap: '6px' }}>
                      <button onClick={() => setEditSupp({ ...s, serving_size: s.serving_size?.toString() ?? '', price: s.price?.toString() ?? '' })} style={btnStyle('#1565c0', '#e3f2fd', '#90caf9')}>수정</button>
                      <button onClick={() => handleDelete(s.id)} style={btnStyle('#d32f2f', '#fff0f0', '#ffcdd2')}>삭제</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div style={{ display: 'flex', justifyContent: 'center', gap: '6px', marginTop: '1.5rem' }}>
            <button onClick={() => handlePageChange(page - 1)} disabled={page === 1} style={{ padding: '8px 14px', borderRadius: '8px', border: '1.5px solid #c8e6c9', backgroundColor: 'white', cursor: page === 1 ? 'not-allowed' : 'pointer', color: page === 1 ? '#aaa' : '#2d8a5e', fontWeight: 600 }}>이전</button>
            {Array.from({ length: totalPages }, (_, i) => i + 1)
              .filter(p => p === 1 || p === totalPages || Math.abs(p - page) <= 2)
              .map((p, idx, arr) => (
                <div key={p} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  {idx > 0 && arr[idx - 1] !== p - 1 && <span style={{ color: '#aaa' }}>...</span>}
                  <button onClick={() => handlePageChange(p)} style={{ padding: '8px 14px', borderRadius: '8px', border: `1.5px solid ${page === p ? '#2d8a5e' : '#c8e6c9'}`, backgroundColor: page === p ? '#2d8a5e' : 'white', color: page === p ? 'white' : '#2d8a5e', cursor: 'pointer', fontWeight: 600 }}>{p}</button>
                </div>
              ))}
            <button onClick={() => handlePageChange(page + 1)} disabled={page === totalPages} style={{ padding: '8px 14px', borderRadius: '8px', border: '1.5px solid #c8e6c9', backgroundColor: 'white', cursor: page === totalPages ? 'not-allowed' : 'pointer', color: page === totalPages ? '#aaa' : '#2d8a5e', fontWeight: 600 }}>다음</button>
          </div>
        </>
      )}

      {showAddModal && (
        <ModalContent
          data={form}
          setData={setForm}
          onConfirm={handleAdd}
          onClose={() => setShowAddModal(false)}
          title="영양제 추가"
        />
      )}

      {editSupp && (
        <ModalContent
          data={editSupp}
          setData={setEditSupp}
          onConfirm={handleUpdate}
          onClose={() => setEditSupp(null)}
          title="영양제 수정"
        />
      )}
    </div>
  )
}