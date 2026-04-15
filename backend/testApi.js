const axios = require('axios');
const url = `http://apis.data.go.kr/1471000/DURPrdlstInfoService1/getUsjntTabooInfoList1?serviceKey=2fbea7cd50d6cd21d011256f288d68b56ab4a3bd645f05ca41f8ff23357898cc&ingrName=${encodeURIComponent('비타민')}&type=json`;
axios.get(url).then(res => console.log(JSON.stringify(res.data, null, 2))).catch(console.error);
