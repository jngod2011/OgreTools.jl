
type DataBase
  firstdate::Date
  lastdate::Date
  data::Dict{String,Any}
end

function DataBase(fd::Date)
  db = DataBase(fd,fd,Dict{String,Any}())
end

function DataBase(rng::OrdinalRange{Date})
  db = DataBase(rng[1],rng[end],Dict{String,Any}())
end

function DataBase(array::Array,varnames::Array{String,1},fd::Date)

  db = DataBase(fd)
  for i = 1:length(varnames)
    db[varnames[i]] = TimeSeries(fd,array[:,i])
  end
  return db
  
end

function Base.show(io::IO,db::DataBase)
  
  vnames = keys(db)
  if length(vnames) <= 8
    print(io,"DataBase(")
    print(io,db.firstdate)
    print(io,", ")
    print(io,db.lastdate)
    print(io,", ")
    print(io,vnames)
    print(io,")")
  else
    print(io,"DataBase(")
    print(io,db.firstdate)
    print(io,", ")
    print(io,db.lastdate)
    print(io,", ")
    print(io,length(vnames))
    print(io," variables)")
  end
  
end

function Base.print(db::DataBase)

  print("\n")

  names = collect(keys(db))
  
  if length(names) == 0
  
    print("Empty database\n")
    
  else
  
    freq = db.firstdate.freq
    if freq == 1
      print(" "^4)
    elseif freq == 4
      print(" "^6)
    elseif freq == 12
      print(" "^7)
    end
    for i = 1:length(names)
      print(lpad(names[i][1:min(length(names[i]),15)],16," "))
    end
    print("\n")
  
    justify!(db)
    
    T = length(db[names[1]])
  
    for d = db.firstdate:db.firstdate + T - 1
    
      print(d)
      
      for i = 1:length(names)
        if i < length(names)
          print(@sprintf("%16.4e",db[names[i]][d].values[1]))
        else
          print(@sprintf("%16.4e\n",db[names[i]][d].values[1]))
        end
      end
      
    end
    
  end
  
end

function Base.print(db::DataBase,threshold)

  # Find the range of large values
  fd =  Inf
  ld = -Inf
  for name in keys(db)
    ind = abs(db[name]) > threshold
    if findfirst(ind) > 0
      fd = min(fd,findfirst(ind))
    end
    if findlast(ind) > 0
      ld = max(ld,findlast(ind))
    end
  end
  
  # Inf is a Float, need to convert to Int
  fd = convert(Int,fd)
  ld = convert(Int,ld)
  
  db1 = DataBase(db.firstdate + fd - 1 : db.firstdate + ld - 1) 
  
  for name in keys(db)
    ind = abs(db[name]) > threshold
    if any(ind)
      db1[name] = db[name][ind]
    else
      db1[name] = NaN
    end
  end
  
  print(db1)
  
end

function Base.setindex!(db::DataBase,ts::TimeSeries,inds::String)

  if ts.firstdate.freq != db.firstdate.freq  
    error("Frequencies must be equal")
  else  
    db.data[inds] = ts
    db.firstdate  = min(db.firstdate,ts.firstdate)
    db.lastdate   = max(db.lastdate, ts.firstdate+length(ts)-1)
  end
  
end

function Base.setindex!(db::DataBase,v::Number,inds::String)

  db[inds] = TimeSeries(db.firstdate:db.lastdate,v)
  
end

function Base.getindex(db::DataBase,inds::String)
  x = db.data[inds]
  return x
end
function Base.getindex(db::DataBase,inds::Array{String,1})
  x = DataBase(db.firstdate)
  for name in inds
    x[name] = db[name]
  end
  return x
end
function Base.getindex(db::DataBase,inds::OrdinalRange)
  x = DataBase(db.firstdate + inds[1] - 1)
  for name in keys(db)
    x[name] = db[name][inds]
  end
  return x
end
function Base.getindex(db::DataBase,inds::OrdinalRange{Date})
  x = DataBase(inds[1])
  for name in keys(db)
    x[name] = db[name][inds]
  end
  return x
end

function Base.keys(db::DataBase)
  return keys(db.data)
end

function Base.values(db::DataBase)
  return values(db.data)
end

function justify!(db::DataBase)

  # # Need to predefine, since loops are "local"
  # fd = Date(db.firstdate.freq,1)
  # ld = Date(db.firstdate.freq,1)
  
  # iffirst = true # Maybe try with enumerate?
  # for ts in values(db.data)
    # if iffirst
      # fd = ts.firstdate
      # ld = ts.firstdate + length(ts) - 1
      # iffirst = false
    # else
      # fd = min(fd,ts.firstdate)
      # ld = max(ld,ts.firstdate + length(ts) - 1)
    # end
  # end
  
  # rng = fd:ld
  
  for name in keys(db)
    extend!(db.data[name],db.firstdate:db.lastdate)
  end
  
end

function db2array(db::DataBase)

  varnames = keys(db)
  array = []
 
  for (i,varname) in enumerate(varnames)
    if i == 1
      N = length(varnames)
      T = length(db[varname])
      array = Array{Number,2}(T,N)
    end
    array[:,i] = db[varname].values
  end
  
  return array
  
end

function db2array(db::DataBase,varnames::Array{String,1})  

  T = length(db[varnames[1]])
  array = Array{Number,2}(T,length(varnames))
  j = 0
  for name in varnames
    j = j+1
    array[:,j] = db[name].values
  end
  
  return array

end